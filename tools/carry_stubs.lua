-- takeCarry's world: the file, the queued copy (_G.BFF_CARRY), JSON (a
-- lookup: encode stores the table under a key, decode returns it).
local NOW = 5000
local os = { time = function() return NOW end }
local DB, FILE, WRITES, CFG, E
local _G = {}
local HttpService = {
    JSONDecode = function(_, s)
        local t = DB[s]
        if not t then error("bad json") end
        return t
    end,
    JSONEncode = function(_, t)
        local k = "enc" .. tostring(#WRITES + 1)
        DB[k] = t
        return k
    end,
}
local function fileRead() return FILE end
local function fileWrite(s) table.insert(WRITES, s) FILE = s return true end
local game = { JobId = "new" }
local function reset()
    DB, FILE, WRITES = {}, nil, {}
    _G.BFF_CARRY = nil
    CFG = { EliteHunt = false, RaidMode = true, RandomMode = false, TravelSpeed = 330 }
    E = { visited = {}, used = false, carried = nil,
          tally = { joins = 0, found = 0, kills = 0, chalices = 0, joinSecs = 0, fails = 0, since = 0 } }
end
reset()
