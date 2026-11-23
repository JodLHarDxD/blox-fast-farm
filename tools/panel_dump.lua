-- After panel_stubs.lua + the PACKS block + the panel: build it, then for
-- each page show it alone with its header as show() draws it (back, title,
-- pack chip; the news strip as Home's rule has it), run one live pass (the
-- readouts and values fill in) and print the panel's tree as JSON -
-- panel_preview.py draws it.
P.panel()
local gui = PG:FindFirstChild("BFFHUD")
local panel
for _, k in ipairs(rawget(gui, "_kids")) do if k.ClassName == "Frame" then panel = k end end
local VIEWS = {}
for _, o in ipairs(ALL) do
    if o.ClassName == "ScrollingFrame" and o.Name ~= "ScrollingFrame" then VIEWS[o.Name] = o end
end

local function q(s)
    s = string.gsub(tostring(s), '[%c"\\]', function(c)
        if c == "\n" then return "\\n" end
        if c == '"' then return '\\"' end
        if c == "\\" then return "\\\\" end
        return " "
    end)
    return '"' .. s .. '"'
end
local function val(v)
    local t = type(v)
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "string" then return q(v) end
    if t == "table" then
        if rawget(v, "_path") then return q(rawget(v, "_path")) end
        if v.X and type(v.X) == "table" then
            return string.format("[%s,%s,%s,%s]", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
        end
        if v.R then return string.format("[%d,%d,%d]", v.R, v.G, v.B) end
        if v.Path then return q(tostring(v.Path) .. "." .. tostring(v.Weight)) end
        if v.Scale then return string.format("[%s,%s]", v.Scale, v.Offset) end
        if v.X then return string.format("[%s,%s]", v.X, v.Y) end
    end
    return "null"
end
local KEEP = { "Name", "Size", "Position", "AnchorPoint", "AutomaticSize", "BackgroundColor3",
    "BackgroundTransparency", "Text", "TextColor3", "TextSize", "Font", "TextXAlignment",
    "TextWrapped", "TextTruncate", "Visible", "LayoutOrder", "PaddingLeft", "PaddingRight",
    "PaddingTop", "PaddingBottom", "Padding", "FillDirection", "HorizontalAlignment", "VerticalAlignment",
    "CornerRadius", "Color", "Transparency", "ClipsDescendants", "ZIndex", "PlaceholderText", "FontFace", "LineHeight", "Rotation", "Wraps", "RichText" }
local function dump(o)
    local props = {}
    for _, k in ipairs(KEEP) do
        local v = rawget(o, "_props")[k]
        if v ~= nil then table.insert(props, q(k) .. ":" .. val(v)) end
    end
    local kids = {}
    for _, k in ipairs(rawget(o, "_kids")) do table.insert(kids, dump(k)) end
    return "{" .. q("c") .. ":" .. q(o.ClassName) .. "," .. q("p") .. ":{" .. table.concat(props, ",")
        .. "}," .. q("k") .. ":[" .. table.concat(kids, ",") .. "]}"
end

-- Every page: the known order first, then any view not listed (a new page
-- shows up without an edit here).
local PAGES = { "home", "modes", "key", "recap", "cover_farm", "cover_raid", "cover_sea",
    "cover_prehistoric", "cover_pvp", "cover_fruits", "circuit", "random", "raid", "elite",
    "sword", "fruit", "fruitmenu", "fruitlog", "trades", "berry", "recipe", "flower", "ember",
    "halloween", "sail", "seaevents", "seafight", "levi", "mirage", "prehistoric", "volcano",
    "pvp", "attack", "weapon", "magnet", "position", "safety", "travel", "servers", "news", "stats" }
do
    local seen, extra = {}, {}
    for _, n in ipairs(PAGES) do seen[n] = true end
    for n in pairs(VIEWS) do if not seen[n] then table.insert(extra, n) end end
    table.sort(extra)
    for _, n in ipairs(extra) do table.insert(PAGES, n) end
end
for _, name in ipairs(PAGES) do
    if not VIEWS[name] then continue end
    for n, v in pairs(VIEWS) do
        v.Visible = (n == name)
        v.Position = UDim2.fromScale(0, 0)
    end
    P.viewNow = name
    if P.newsStripNow then P.newsStripNow() end
    -- the header as show() draws it
    local row, back
    for _, o in ipairs(ALL) do
        if o.Name == "TitleRow" then row = o end
        if o.Name == "Back" then back = o end
    end
    if back then back.Visible = name ~= "home" end
    if row then
        row.Position = UDim2.fromOffset(name == "home" and 20 or 54, 2)
        for _, k in ipairs(rawget(row, "_kids")) do
            -- the title: panel_preview.py puts the page's name in (TITLES)
            if k.ClassName == "TextLabel" and k.LayoutOrder == 1 then k.Text = "@@title:" .. name end
            if k.Name == "PackChip" then k:Destroy() end
        end
        local pk = P.pagePack and P.pagePack[name]
        if pk then local ch = P.kit.packChip(row, pk) ch.Name, ch.LayoutOrder = "PackChip", 2 end
    end
    pcall(SPAWNED[#SPAWNED])
    print("PAGE " .. name .. " " .. dump(panel))
end
