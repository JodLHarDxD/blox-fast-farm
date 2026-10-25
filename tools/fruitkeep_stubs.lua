-- What the trade values and the fruit history touch, faked: the executor's
-- files (FILES[name] = a copy of the table the JSON stands for), the player.
local P = {}
local player = { UserId = 7 }
local FILES, WRITES = {}, 0
local function copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = copy(v) end
    return o
end
local function readfile(n)
    if FILES[n] == nil then error("no such file") end
    return n
end
local function writefile(n, s) FILES[n] = s WRITES += 1 end
local HttpService = {
    JSONEncode = function(_, t) return copy(t) end,
    JSONDecode = function(_, s) return copy(FILES[s]) end,
}
local game = { GetService = function(_, n) return n == "HttpService" and HttpService or nil end }
