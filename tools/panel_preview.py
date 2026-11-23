"""Draw the panel without the game: the REAL PANEL section built in luau.exe
with the panel test's stand-ins (panel_stubs.lua), every page dumped
(panel_dump.lua) and drawn as HTML - one card per page, its whole length, a
dashed line where the window ends (below it = scrolled to). Roblox's layout
is approximated: UIListLayout = a flex column/row, AutomaticSize = auto
height (a frame that grows takes its first growing child into its flow),
FontFace Montserrat = Montserrat at TextSize / 1.21 (LOOK_EM), Code = a
monospace. Good for spacing, overlap
and truncation; the game has the last word.

usage: python tools/panel_preview.py [out.html] [Key=value ...]
       (default: panel_preview.html next to this file; Key=value sets a CFG
       value first, e.g. SeaSteer=auto)
"""
import html
import re
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LUAU = r"C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe"
ARGS = [a for a in sys.argv[1:] if "=" not in a]
OUT = ARGS[0] if ARGS else os.path.join(HERE, "panel_preview.html")
# Key=value: a CFG value to draw the pages with (SeaSteer=auto, Magnet=false)


def lua_value(s):
    if s in ("true", "false", "nil"):
        return s
    try:
        float(s)
        return s
    except ValueError:
        return '"' + s.replace('"', '\\"') + '"'


SETS = "".join("CFG_REAL.%s = %s\n" % (k, lua_value(v))
               for k, v in (a.split("=", 1) for a in sys.argv[1:] if "=" in a))


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
pa = src.index("-- PACKS (2026-11-22)")
packs = src[pa:src.index("-- PACKS END", pa)]
lua = (stubs[:cut] + cfg + "local CFG_REAL = CFG\nCFG = proxy(CFG_REAL, \"\")\n"
       + stubs[stubs.index("\n", cut) + 1:] + packs + panel + SETS + read("panel_dump.lua"))
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
PAGE_NAMES = {n for n, _ in pages}

# The header's title per page (fast_farm.lua's TITLES / P.headTitle).
TITLES = {
    "home": "Fast Farm · " + build, "modes": "Modes", "circuit": "Circuit farm", "random": "Random",
    "raid": "Raid", "elite": "Elite pirates", "fruit": "Fruits", "fruitlog": "Fruit history",
    "berry": "Haki berries", "recipe": "Aura recipe", "sword": "Swords", "flower": "Fire Flower",
    "ember": "Blaze Ember", "halloween": "Halloween", "sail": "Sea travel", "seaevents": "Sea events",
    "prehistoric": "Prehistoric", "mirage": "Mirage", "levi": "Leviathan", "pvp": "PvP",
    "volcano": "Volcano event", "seafight": "Sea fight", "attack": "Attack", "weapon": "Weapon",
    "magnet": "Magnet", "position": "Position", "safety": "Safety & haki", "travel": "Travel & boat",
    "servers": "Servers & team", "stats": "Stats & debug", "news": "Breaking news",
    "fruitmenu": "Fruit menu", "trades": "Trades", "cover_farm": "Grind", "cover_raid": "Bosses + Raids",
    "cover_sea": "Sea", "cover_prehistoric": "Prehistoric", "cover_pvp": "PvP", "cover_fruits": "Fruits",
    "key": "Key & packs", "recap": "Your trial",
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


def rich(s, k):
    """RichText's <font color / weight / size>, <b>, <i>, <br/> as HTML."""
    def font(m):
        a = m.group(1)
        st = []
        for name, val in re.findall(r'(\w+)="([^"]*)"', a):
            if name == "color":
                st.append("color:" + val)
            elif name == "weight":
                st.append("font-weight:" + {"bold": "700", "heavy": "800"}.get(val.lower(), val))
            elif name == "size":
                st.append("font-size:%.2fpx" % (float(val) / k))
        return '<span style="%s">' % ";".join(st)
    parts = re.split(r"(<[^>]+>)", s)
    out = []
    for t in parts:
        if t.startswith("<font"):
            out.append(font(re.match(r"<font(.*)>", t)))
        elif t == "</font>":
            out.append("</span>")
        elif t in ("<b>", "</b>", "<i>", "</i>", "<br/>", "<br />"):
            out.append(t)
        else:
            out.append(html.escape(t))
    return "".join(out)


SKIP = ("UIListLayout", "UIPadding", "UICorner", "UIStroke", "UIGradient", "UIScale", "UISizeConstraint")


def render(node, in_list, page_name, depth=0, flow=False):
    c, p, kids = node["c"], node["p"], node["k"]
    if c in ("UIListLayout", "UIPadding", "UICorner", "UIStroke", "UIGradient", "UIScale", "UISizeConstraint"):
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
    is_view = c == "ScrollingFrame" and p.get("Name") in PAGE_NAMES
    st.append("box-sizing:border-box")
    if p.get("Name") == "__body__":
        # The body drawn in the flow under the title + news strip, so the
        # card grows to the page's whole length.
        st.append("position:relative;margin-top:%dpx" % HEADY)
    elif is_view:
        st.append("position:relative")
    elif flow:
        # the growing child of a growing frame with no layout: in the flow,
        # so the parent grows round it as Roblox's AutomaticSize does
        pos = p.get("Position", [0, 0, 0, 0])
        st.append(f"position:relative;margin-left:{pos[1]}px;margin-top:{pos[3]}px")
    elif in_list:
        st.append("position:relative;flex:none")
        st.append(f"order:{p.get('LayoutOrder', 0)}")
    else:
        st.append("position:absolute")
        pos = p.get("Position", [0, 0, 0, 0])
        st.append(f"left:{dim(pos, 'x')};top:{dim(pos, 'y')}")
        an = p.get("AnchorPoint")
        tf = []
        if an and (an[0] or an[1]):
            tf.append(f"translate({-an[0] * 100}%,{-an[1] * 100}%)")
        if p.get("Rotation"):
            tf.append(f"rotate({p['Rotation']}deg)")       # round its middle, as Roblox turns it
        if tf:
            st.append("transform:" + " ".join(tf))
    if "AutomaticSize.X" in auto:
        st.append("width:max-content")
    else:
        st.append(f"width:{dim(size, 'x')}")
    if "AutomaticSize.Y" in auto or is_view:
        # Roblox grows a frame round EVERY child (fixed ones too); CSS only
        # round those in its flow - the fixed ones' bottoms set the floor
        need = 0
        if not any(k["c"] == "UIListLayout" for k in kids):
            for k in kids:
                kp = k["p"]
                if k["c"] in SKIP or kp.get("Visible") is False:
                    continue
                ks, kq = kp.get("Size", [0, 0, 0, 0]), kp.get("Position", [0, 0, 0, 0])
                if ks[2] == 0 and kq[2] == 0 and "AutomaticSize.Y" not in kp.get("AutomaticSize", ""):
                    need = max(need, kq[3] + ks[3])
            if need and pad:
                need += sum(pad["p"].get(x, [0, 0])[1] for x in ("PaddingTop", "PaddingBottom"))
        st.append(f"height:auto;min-height:max({dim(size, 'y')}, {need}px)")
    else:
        st.append(f"height:{dim(size, 'y')}")
    bt = p.get("BackgroundTransparency", 0)
    if bt < 1 and "BackgroundColor3" in p and c != "UIListLayout":
        st.append(f"background:{rgb(p['BackgroundColor3'])}")
    if cor:
        st.append(f"border-radius:{cor['p'].get('CornerRadius', [0, 0])[1]}px")
    if stroke and (stroke["p"].get("Transparency") or 0) < 0.99:
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
        fam, w = FONTS.get(p.get("Font", ""), ("'Montserrat', sans-serif", 400))
        ff = p.get("FontFace") or ""
        WM = {"Regular": 400, "Medium": 500, "SemiBold": 600, "Bold": 700, "ExtraBold": 800}
        if "Montserrat" in ff:
            fam = "'Montserrat', sans-serif"
            w = WM.get(ff.split(".")[-1], 400)
        elif "Code" in ff:
            fam = "'Inconsolata', monospace"
            w = 400
        lh = p.get("LineHeight", 1) or 1
        k = 1.21 if "Montserrat" in fam else 1.0
        st.append(f"font-family:{fam};font-weight:{w};font-size:{p.get('TextSize', 14) / k:.2f}px")
        st.append(f"color:{rgb(p.get('TextColor3', [0, 0, 0]))};line-height:{1.219 * lh:.3f}")
        xa = p.get("TextXAlignment", "Enum.TextXAlignment.Center").split(".")[-1]
        st.append({"Left": "text-align:left", "Right": "text-align:right"}.get(xa, "text-align:center"))
        # an empty text button is a plain box: its children keep their own
        # places (no centring flex)
        boxy = not text and any(k["c"] not in SKIP for k in kids)
        if p.get("TextWrapped"):
            st.append("white-space:pre-wrap")
            if "AutomaticSize.Y" not in auto and not boxy:
                st.append("display:flex;align-items:center;justify-content:"
                          + {"Left": "flex-start", "Right": "flex-end"}.get(xa, "center"))
        elif not boxy:
            st.append("white-space:pre;display:flex;align-items:center;justify-content:"
                      + {"Left": "flex-start", "Right": "flex-end"}.get(xa, "center"))
        if p.get("TextTruncate") == "Enum.TextTruncate.AtEnd":
            inner = f'<span style="overflow:hidden;text-overflow:ellipsis;white-space:pre;max-width:100%">{html.escape(str(text or ""))}</span>'
        else:
            inner = html.escape(str(text or ""))
        if p.get("RichText"):
            inner = rich(str(text or ""), k)
        if str(text or "").startswith("@@title:"):
            inner = html.escape(TITLES.get(page_name, page_name))
    if layout:
        lp = layout["p"]
        row = lp.get("FillDirection") == "Enum.FillDirection.Horizontal"
        st.append("display:flex;flex-direction:" + ("row" if row else "column"))
        g = lp.get("Padding", [0, 0])[1]
        if g:
            st.append(f"gap:{g}px")
        if lp.get("Wraps"):
            st.append("flex-wrap:wrap")
        if row:
            st.append("align-items:" + ("center" if lp.get("VerticalAlignment") == "Enum.VerticalAlignment.Center"
                                        else "flex-start"))
        elif lp.get("HorizontalAlignment") == "Enum.HorizontalAlignment.Center":
            st.append("align-items:center")
        else:
            st.append("align-items:flex-start")
    grower = None
    if not layout and ("AutomaticSize.Y" in auto or "AutomaticSize.X" in auto):
        axis = "Y" if "AutomaticSize.Y" in auto else "X"

        def grows(k, ax):
            a = k["p"].get("AutomaticSize", "")
            return (k["p"].get("Visible") is not False and k["c"] not in SKIP
                    and (("AutomaticSize." + ax) in a or "AutomaticSize.XY" in a))
        grower = next((k for k in kids if grows(k, axis)), None)
    kids_html = "".join(render(k, layout is not None, page_name, depth + 1, k is grower) for k in kids)
    if pad and not layout and kids_html:
        # Roblox places a child inside the padding; CSS's absolute boxes sit
        # on the padding's outer edge - a content-box wrapper puts them back.
        hh = "auto" if ("AutomaticSize.Y" in auto or is_view) else "100%"
        kids_html = f'<div style="position:relative;width:100%;height:{hh}">{kids_html}</div>'
    return f'<div style="{";".join(st)}">{inner}{kids_html}</div>'


cards = []
for name, root in pages:
    # The title (the bold 15 px label on the panel) says this page's name;
    # Back shows on every page but Home.
    HEADY = 48
    for k in root["k"]:
        kp = k["p"]
        if kp.get("Name") == "NewsStrip" and kp.get("Visible"):
            HEADY = 82
    h = root["p"]["Size"][3]
    root["p"]["Size"] = [0, 342, 0, h]
    root["p"]["Position"] = [0, 0, 0, 0]
    root["p"]["AnchorPoint"] = [0, 0]
    root["p"]["AutomaticSize"] = "Enum.AutomaticSize.Y"
    for k in root["k"]:
        if k["c"] == "Frame" and k["p"].get("ClipsDescendants") and k["p"].get("Size", [0])[0] == 1:
            k["p"]["ClipsDescendants"] = False
            k["p"]["AutomaticSize"] = "Enum.AutomaticSize.Y"
            k["p"]["Size"] = [1, 0, 0, h - HEADY]
            k["p"]["Name"] = "__body__"
    # flow-root: the body's top margin stays inside the card (CSS
    # would otherwise collapse it through the card's top).
    body = render(root, False, name).replace("position:absolute", "position:relative;display:flow-root", 1)
    cards.append(f'<figure id="p-{name}"><figcaption>{html.escape(name)}</figcaption><div class="frame" style="height:auto">'
                 f'{body}<div class="fold" style="top:{h}px"><span>window ends ({h} px)</span></div></div></figure>')

doc = f"""<!doctype html><meta charset="utf-8"><title>Fast Farm panel preview</title>
<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700;800&family=Inconsolata&display=swap" rel="stylesheet">
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
