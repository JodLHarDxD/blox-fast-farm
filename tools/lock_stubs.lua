-- Stubs for the SETTINGS LOCK (lock_test.py): an in-memory workspace folder,
-- an HttpService whose "JSON" is a registry of copies (the section only ever
-- writes what LK.plain lets through), a fake clock. The REAL section is run
-- once per "load" inside runSection().
local FS = {}
local CAN_WRITE = true
local function deep(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = deep(x) end
    return t
end
local REG, regN = {}, 0
local HttpService = {
    JSONEncode = function(_, t)
        regN += 1
        local key = "json#" .. regN
        REG[key] = deep(t)
        return key
    end,
    JSONDecode = function(_, s)
        if s == '{"v":1,"locked":false}' then return { v = 1, locked = false } end
        local t = REG[s]
        if t == nil then error("not JSON: " .. tostring(s)) end
        return deep(t)
    end,
}
local game = { GetService = function(_, n) if n == "HttpService" then return HttpService end end }
local function writefileImpl(name, s) FS[name] = s end
local writefile = function(name, s)
    if not CAN_WRITE then error("no file system") end
    writefileImpl(name, s)
end
local readfile = function(name) return FS[name] end
local isfile = function(name) return FS[name] ~= nil end
local task = { spawn = function() end, wait = function() end }
local os = { date = function() return "12:00:00" end, clock = function() return 0 end }
local player = { UserId = 42 }
local realPrint = print
local printed = {}
local print = function(s) table.insert(printed, s) end

local CFG, P
local fails, count = 0, 0
local function check(name, cond)
    count += 1
    if not cond then
        fails += 1
        realPrint("FAIL  " .. name)
    end
end
