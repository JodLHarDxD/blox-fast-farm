-- PlayerGui and _WorldOrigin.Locations, faked.
local V3 = {}
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end
local function node(name, class, kids, props)
    local n = { Name = name, ClassName = class, kids = kids or {} }
    for k, v in pairs(props or {}) do n[k] = v end
    function n:FindFirstChild(c) for _, k in ipairs(self.kids) do if k.Name == c then return k end end end
    function n:IsA(c)
        if c == "GuiObject" then return self.ClassName == "Frame" or self.ClassName == "TextLabel" end
        if c == "BasePart" then return self.ClassName == "Part" end
        return self.ClassName == c
    end
    function n:FindFirstChildWhichIsA(c, _)
        for _, k in ipairs(self.kids) do if k:IsA(c) then return k end end
    end
    function n:GetPivot() return { Position = self.pivot } end
    return n
end
local PG = node("PlayerGui", "PlayerGui")
local player = node("Player", "Player", { PG })
local LOC = node("Locations", "Folder")
local workspace = node("Workspace", "Workspace", { node("_WorldOrigin", "Folder", { LOC }) })
local P = {}
