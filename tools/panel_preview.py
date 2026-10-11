"""Draw the panel without the game: the REAL PANEL section built in luau.exe
with the panel test's stand-ins (panel_stubs.lua), every page dumped
(panel_dump.lua) and drawn as HTML - one card per page, its whole length, a
dashed line where the window ends (below it = scrolled to). Roblox's layout
is approximated: UIListLayout = a flex column/row, AutomaticSize = auto
height, Gotham = Montserrat, Code = a monospace. Good for spacing, overlap
and truncation; the game has the last word.

usage: python tools/panel_preview.py [out.html]      (default: panel_preview.html next to this file)
"""
import html
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "panel_preview.html")


def read(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as f:
        return f.read()


src = read(os.path.join("..", "fast_farm.lua"))
a = src.index("local CFG = {")
cfg = src[a:src.index("\n}\n", a) + 3]
p = src.index("-- PANEL\n")
panel = src[p:src.index("-- API\n", p)]
build = src[src.index('build = "') + 9:]
build = build[:build.index('"')]
stubs = read("panel_stubs.lua")
cut = stubs.index("-- @@CFG@@")
lua = (stubs[:cut] + cfg + "local CFG_REAL = CFG\nCFG = proxy(CFG_REAL, \"\")\n"
       + stubs[stubs.index("\n", cut) + 1:] + panel + read("panel_dump.lua"))
with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
    f.write(lua)
    path = f.name
r = subprocess.run([LUAU, path], capture_output=True, text=True, encoding="utf-8")
os.unlink(path)
pages = []
for line in r.stdout.splitlines():
    if line.startswith("PAGE "):
        name, js = line[5:].split(" ", 1)
        pages.append((name, json.loads(js)))
if not pages:
    print(r.stdout + r.stderr)
    sys.exit(1)

TITLES = {
    "home": "Fast Farm  ·  " + build, "modes": "Modes", "circuit": "Circuit farm", "random": "Random",
    "raid": "Raid", "elite": "Elite pirates", "fruit": "Fruits", "berry": "Haki berries",
    "recipe": "Aura recipe", "sword": "Legendary swords", "flower": "Fire Flower", "ember": "Blaze Ember",
    "sail": "Sea travel", "seaevents": "Sea events", "prehistoric": "Prehistoric", "mirage": "Mirage",
    "levi": "Leviathan", "pvp": "PvP", "volcano": "Volcano event", "seafight": "Fighting at sea",
    "attack": "Attack", "weapon": "Godhuman", "magnet": "Magnet", "position": "Position",
    "safety": "Safety & haki", "travel": "Travel & boat", "servers": "Servers & team",
    "stats": "Stats & debug",
}
FONTS = {
    "Enum.Font.GothamBold": ("'Montserrat', 'Segoe UI', sans-serif", 700),
    "Enum.Font.GothamMedium": ("'Montserrat', 'Segoe UI', sans-serif", 500),
    "Enum.Font.Gotham": ("'Montserrat', 'Segoe UI', sans-serif", 400),
    "Enum.Font.Code": ("'Inconsolata', 'Consolas', monospace", 400),
}


def dim(d, axis):
    s, o = (d[0], d[1]) if axis == "x" else (d[2], d[3])
    if s == 0:
        return f"{o}px"
    return f"calc({s * 100}% + {o}px)"


def rgb(c):
    return f"rgb({c[0]},{c[1]},{c[2]})"


def render(node, in_list, page_name, depth=0):
    c, p, kids = node["c"], node["p"], node["k"]
    if c in ("UIListLayout", "UIPadding", "UICorner", "UIStroke", "UIGradient"):
        return ""
    if p.get("Visible") is False:
        return ""
    st = []
    layout = next((k for k in kids if k["c"] == "UIListLayout"), None)
    pad = next((k for k in kids if k["c"] == "UIPadding"), None)
    cor = next((k for k in kids if k["c"] == "UICorner"), None)
    stroke = next((k for k in kids if k["c"] == "UIStroke"), None)
    size = p.get("Size", [0, 0, 0, 0])
    auto = p.get("AutomaticSize", "")
    is_view = c == "ScrollingFrame" and p.get("Name") in TITLES
    st.append("box-sizing:border-box")
    if p.get("Name") == "__body__":
        # The body drawn in the flow under the title + news strip, so the
        # card grows to the page's whole length.
        st.append("position:relative;margin-top:82px")
    elif is_view:
        st.append("position:relative")
    elif in_list:
        st.append("position:relative;flex:none")
        st.append(f"order:{p.get('LayoutOrder', 0)}")
    else:
        st.append("position:absolute")
        pos = p.get("Position", [0, 0, 0, 0])
        st.append(f"left:{dim(pos, 'x')};top:{dim(pos, 'y')}")
        an = p.get("AnchorPoint")
        if an and (an[0] or an[1]):
            st.append(f"transform:translate({-an[0] * 100}%,{-an[1] * 100}%)")
    if "AutomaticSize.X" in auto:
        st.append("width:max-content")
    else:
        st.append(f"width:{dim(size, 'x')}")
    if "AutomaticSize.Y" in auto or is_view:
        st.append(f"height:auto;min-height:{dim(size, 'y')}")
    else:
        st.append(f"height:{dim(size, 'y')}")
    bt = p.get("BackgroundTransparency", 0)
    if bt < 1 and "BackgroundColor3" in p and c != "UIListLayout":
        st.append(f"background:{rgb(p['BackgroundColor3'])}")
    if cor:
        st.append(f"border-radius:{cor['p'].get('CornerRadius', [0, 0])[1]}px")
    if stroke:
        st.append(f"outline:1px solid {rgb(stroke['p'].get('Color', [80, 80, 80]))}")
    if p.get("ClipsDescendants") and not is_view and c != "ScrollingFrame":
        st.append("overflow:hidden")
    if c == "ScrollingFrame" and not is_view:
        st.append("overflow:hidden")
    if pad:
        pp = pad["p"]
        st.append("padding:%spx %spx %spx %spx" % tuple(pp.get(k, [0, 0])[1] for k in
                  ("PaddingTop", "PaddingRight", "PaddingBottom", "PaddingLeft")))
    inner = ""
    text = p.get("Text")
    if c in ("TextLabel", "TextButton", "TextBox"):
        if not text and c == "TextBox":
            text = p.get("PlaceholderText", "")
        fam, w = FONTS.get(p.get("Font", ""), ("sans-serif", 400))
        st.append(f"font-family:{fam};font-weight:{w};font-size:{p.get('TextSize', 14)}px")
        st.append(f"color:{rgb(p.get('TextColor3', [0, 0, 0]))};line-height:1.2")
        xa = p.get("TextXAlignment", "Enum.TextXAlignment.Center").split(".")[-1]
        st.append({"Left": "text-align:left", "Right": "text-align:right"}.get(xa, "text-align:center"))
        if p.get("TextWrapped"):
            st.append("white-space:pre-wrap")
            if "AutomaticSize.Y" not in auto:
                st.append("display:flex;align-items:center;justify-content:"
                          + {"Left": "flex-start", "Right": "flex-end"}.get(xa, "center"))
        else:
            st.append("white-space:pre;display:flex;align-items:center;justify-content:"
                      + {"Left": "flex-start", "Right": "flex-end"}.get(xa, "center"))
        if p.get("TextTruncate") == "Enum.TextTruncate.AtEnd":
            inner = f'<span style="overflow:hidden;text-overflow:ellipsis;white-space:pre;max-width:100%">{html.escape(str(text or ""))}</span>'
        else:
            inner = html.escape(str(text or ""))
        if p.get("Name") == "__heading__":
            inner = html.escape(TITLES.get(page_name, page_name))
    if layout:
        lp = layout["p"]
        row = lp.get("FillDirection") == "Enum.FillDirection.Horizontal"
        st.append("display:flex;flex-direction:" + ("row" if row else "column"))
        g = lp.get("Padding", [0, 0])[1]
        if g:
            st.append(f"gap:{g}px")
        if row:
            st.append("align-items:" + ("center" if lp.get("VerticalAlignment") == "Enum.VerticalAlignment.Center"
                                        else "flex-start"))
        elif lp.get("HorizontalAlignment") == "Enum.HorizontalAlignment.Center":
            st.append("align-items:center")
        else:
            st.append("align-items:flex-start")
    kids_html = "".join(render(k, layout is not None, page_name, depth + 1) for k in kids)
    return f'<div style="{";".join(st)}">{inner}{kids_html}</div>'


cards = []
for name, root in pages:
    # The title (the bold 15 px label on the panel) says this page's name;
    # Back shows on every page but Home.
    for k in root["k"]:
        kp = k["p"]
        if k["c"] == "TextLabel" and kp.get("Font") == "Enum.Font.GothamBold" and kp.get("TextSize") == 15:
            kp["Name"] = "__heading__"
            if name != "home":
                kp["Position"] = [0, 76, 0, 18]
        if k["c"] == "TextButton" and kp.get("Text") == "Back":
            kp["Visible"] = name != "home"
    h = root["p"]["Size"][3]
    root["p"]["Size"] = [0, 342, 0, h]
    root["p"]["Position"] = [0, 0, 0, 0]
    root["p"]["AutomaticSize"] = "Enum.AutomaticSize.Y"
    for k in root["k"]:
        if k["c"] == "Frame" and k["p"].get("ClipsDescendants") and k["p"].get("Size", [0])[0] == 1:
            k["p"]["ClipsDescendants"] = False
            k["p"]["AutomaticSize"] = "Enum.AutomaticSize.Y"
            k["p"]["Size"] = [1, 0, 0, h - 82]
            k["p"]["Name"] = "__body__"
    # flow-root: the body's 82 px top margin stays inside the card (CSS
    # would otherwise collapse it through the card's top).
    body = render(root, False, name).replace("position:absolute", "position:relative;display:flow-root", 1)
    cards.append(f'<figure id="p-{name}"><figcaption>{html.escape(name)}</figcaption><div class="frame" style="height:auto">'
                 f'{body}<div class="fold" style="top:{h}px"><span>window ends ({h} px)</span></div></div></figure>')

doc = f"""<!doctype html><meta charset="utf-8"><title>Fast Farm panel preview</title>
<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;700&family=Inconsolata&display=swap" rel="stylesheet">
<style>
body{{margin:0;padding:24px;background:#3a4a5c;font-family:'Segoe UI',sans-serif}}
.grid{{display:flex;flex-wrap:wrap;gap:28px;align-items:flex-start}}
figure{{margin:0}} figcaption{{color:#dfe6ee;font:600 13px 'Segoe UI';margin:0 0 6px}}
.frame{{position:relative;width:342px}}
.fold{{position:absolute;left:-6px;right:-6px;border-top:2px dashed #ff6b6b;pointer-events:none}}
.fold span{{position:absolute;right:0;top:2px;font:600 10px 'Segoe UI';color:#ff6b6b;background:#3a4a5c;padding:0 4px}}
</style><div class="grid">{''.join(cards)}</div>"""
with open(OUT, "w", encoding="utf-8") as f:
    f.write(doc)
print(f"{len(pages)} pages -> {OUT}")
