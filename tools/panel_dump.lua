-- After panel_stubs.lua + the panel: build it, then for each page show it
-- alone, run one live pass (the readouts and values fill in) and print the
-- panel's tree as JSON - panel_preview.py draws it.
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
        if v.Scale then return string.format("[%s,%s]", v.Scale, v.Offset) end
        if v.X then return string.format("[%s,%s]", v.X, v.Y) end
    end
    return "null"
end
local KEEP = { "Name", "Size", "Position", "AnchorPoint", "AutomaticSize", "BackgroundColor3",
    "BackgroundTransparency", "Text", "TextColor3", "TextSize", "Font", "TextXAlignment",
    "TextWrapped", "TextTruncate", "Visible", "LayoutOrder", "PaddingLeft", "PaddingRight",
    "PaddingTop", "PaddingBottom", "Padding", "FillDirection", "HorizontalAlignment", "VerticalAlignment",
    "CornerRadius", "Color", "Transparency", "ClipsDescendants", "ZIndex", "PlaceholderText" }
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

local PAGES = { "home", "modes", "circuit", "random", "raid", "elite", "fruit", "berry",
    "recipe", "sword", "flower", "ember", "sail", "seaevents", "prehistoric", "mirage", "levi",
    "pvp", "volcano", "seafight", "attack", "weapon", "magnet", "position", "safety", "travel",
    "servers", "stats" }
for _, name in ipairs(PAGES) do
    for n, v in pairs(VIEWS) do
        v.Visible = (n == name)
        v.Position = UDim2.fromScale(0, 0)
    end
    pcall(SPAWNED[#SPAWNED])
    print("PAGE " .. name .. " " .. dump(panel))
end
