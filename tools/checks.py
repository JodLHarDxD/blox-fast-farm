"""Two checks luau-compile and luau-analyze cannot do for a Roblox script.

fieldcheck: every CFG.x / stats.x read is a key the table literal defines,
            and every P.x read is assigned somewhere (P.x = ... / function P.x).
hoistcheck: no file-level local is used ABOVE its declaration. Lua does not
            hoist locals: such a use resolves to a nil global and throws when
            indexed. luau-analyze only calls it "Unknown global", buried under
            Roblox's own globals, so it is invisible without this.

usage: python tools/checks.py fast_farm.lua        (exit 1 on any finding)
"""
import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else "fast_farm.lua"
src = open(path, encoding="utf-8").read()


def strip(text):
    """Blank out comments and strings, keep line structure."""
    out, i, n = [], 0, len(text)
    while i < n:
        if text.startswith("--[[", i) or re.match(r"--\[=*\[", text[i:i + 8] or ""):
            m = re.match(r"--\[(=*)\[", text[i:])
            close = "]" + m.group(1) + "]"
            j = text.find(close, i)
            j = n if j < 0 else j + len(close)
            out.append(re.sub(r"[^\n]", " ", text[i:j])); i = j
        elif text.startswith("--", i):
            j = text.find("\n", i); j = n if j < 0 else j
            out.append(" " * (j - i)); i = j
        elif text[i] in "\"'":
            q, j = text[i], i + 1
            while j < n and text[j] != q:
                j += 2 if text[j] == "\\" else 1
            j += 1
            out.append(re.sub(r"[^\n]", " ", text[i:j])); i = j
        elif re.match(r"\[=*\[", text[i:i + 8]):
            m = re.match(r"\[(=*)\[", text[i:])
            close = "]" + m.group(1) + "]"
            j = text.find(close, i)
            j = n if j < 0 else j + len(close)
            out.append(re.sub(r"[^\n]", " ", text[i:j])); i = j
        else:
            out.append(text[i]); i += 1
    return "".join(out)


code = strip(src)
lines = code.split("\n")
bad = 0


def table_keys(name):
    m = re.search(r"^local " + name + r"\s*=\s*\{", code, re.M)
    if not m:
        return None
    depth, i = 0, m.end() - 1
    start = i
    while i < len(code):
        if code[i] == "{": depth += 1
        elif code[i] == "}":
            depth -= 1
            if depth == 0: break
        i += 1
    body = code[start:i]
    return set(re.findall(r"^\s*([A-Za-z_]\w*)\s*=", body, re.M)) | \
        set(re.findall(r"[{,]\s*([A-Za-z_]\w*)\s*=", body))


# ---------- fieldcheck ----------
for tbl in ("CFG", "stats"):
    keys = table_keys(tbl)
    if keys is None:
        print(f"fieldcheck: no table literal for {tbl}"); bad += 1; continue
    for m in re.finditer(r"(?<![\w.])" + tbl + r"\.([A-Za-z_]\w*)", code):
        if m.group(1) not in keys:
            ln = code.count("\n", 0, m.start()) + 1
            print(f"fieldcheck: {tbl}.{m.group(1)} not in the {tbl} table  (line {ln})")
            bad += 1

assigned = set(re.findall(r"(?<![\w.])P\.([A-Za-z_]\w*)\s*=(?!=)", code))
assigned |= set(re.findall(r"function\s+P\.([A-Za-z_]\w*)", code))
for m in re.finditer(r"((?:(?<![\w.])P\.[A-Za-z_]\w*\s*,\s*)+P\.[A-Za-z_]\w*)\s*=(?!=)", code):
    assigned |= set(re.findall(r"P\.([A-Za-z_]\w*)", m.group(1)))
assigned |= table_keys("P") or set()
for m in re.finditer(r"(?<![\w.])P\.([A-Za-z_]\w*)", code):
    if m.group(1) not in assigned:
        ln = code.count("\n", 0, m.start()) + 1
        print(f"fieldcheck: P.{m.group(1)} read but never assigned  (line {ln})")
        bad += 1

# ---------- hoistcheck ----------
decl = {}
for ln, line in enumerate(lines, 1):
    m = re.match(r"local\s+function\s+([A-Za-z_]\w*)", line)
    names = [m.group(1)] if m else []
    if not m:
        m = re.match(r"local\s+([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)", line)
        if m:
            names = [x.strip() for x in m.group(1).split(",")]
    for nm in names:
        decl.setdefault(nm, ln)

# names declared as locals inside functions (indented) shadow nothing we care
# about above them only if they are declared in that same scope; report and
# let a human look -- the list is short.
inner = {}
for ln, line in enumerate(lines, 1):
    for m in re.finditer(r"(?:^|\s)local\s+(?:function\s+)?([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)", line):
        if line.startswith("local"):
            continue
        for nm in m.group(1).split(","):
            inner.setdefault(nm.strip(), []).append(ln)
    for m in re.finditer(r"function\s*[\w.:]*\(([^)]*)\)", line):
        for nm in m.group(1).split(","):
            nm = nm.strip()
            if nm and nm != "...":
                inner.setdefault(nm, []).append(ln)
    for m in re.finditer(r"for\s+([\w\s,]+?)\s+(?:in|=)", line):
        for nm in m.group(1).split(","):
            inner.setdefault(nm.strip(), []).append(ln)

for nm, dln in decl.items():
    pat = re.compile(r"(?<![\w.:])" + re.escape(nm) + r"(?!\w)(?!\s*=[^=])")
    for ln in range(1, dln):
        line = lines[ln - 1]
        for m in pat.finditer(line):
            # table-constructor key "{ nm = ..." is excluded by the lookahead;
            # a local/param of the same name declared at or above this line
            # inside a function is a different variable.
            if any(l <= ln for l in inner.get(nm, [])):
                continue
            print(f"hoistcheck: '{nm}' used at line {ln}, declared at line {dln}")
            bad += 1
            break

print("checks: " + ("clean" if bad == 0 else f"{bad} finding(s)"))
sys.exit(1 if bad else 0)
