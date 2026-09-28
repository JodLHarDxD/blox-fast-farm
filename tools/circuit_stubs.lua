-- The circuit's world: your targets, your level row, which sea you are in.
local CFG = { Targets = {} }
local P = {}
local SEA = 2
local function mySea() return SEA end
local function seaOfLevel(lv)
    if lv < 700 then return 1 elseif lv < 1500 then return 2 end
    return 3
end
local LEVELS = {
    { 1500, 1524, "Pirate Millionaire", { X = 81 } },
    { 2600, 2800, "Grand Devotee", { X = 9591 } },
}
local BOSS = {
    Diamond = { lv = 750, spot = { X = -1569 } },
    Stone   = { lv = 1550, spot = { X = -1049 } },
}
local function rowOf(name) for _, r in ipairs(LEVELS) do if r[3] == name then return r end end end
local function levelOf(name)
    local r = rowOf(name)
    if r then return r[1] end
    return BOSS[name] and BOSS[name].lv or nil
end
local LEVEL_ROW = LEVELS[2]
local function levelRow() return LEVEL_ROW end
