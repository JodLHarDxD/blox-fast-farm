
-- What autoexec_resume.lua touches, faked. mk(opts) builds one join:
--   place      the PlaceId once loaded
--   loaded     false = the game is still loading (PlaceId 0 until Loaded)
--   flag       the Guard's note as a table (nil = no file), written as JSON
--   raw        the note's raw text instead (garbage, say)
--   age        how old the note is, seconds (default 30)
--   bff        _G.BFF already there (loaded by hand / a queued reload)
--   getFails   game:HttpGet errors
--   noCompile  loadstring returns nil
--   noDelfile  the executor has no delfile
--   selfStart  the loaded copy starts by itself (a carried-over hunt)
--   startFails _G.BFF.start errors
-- The file runs as RUN(game, task, print); its `return`s end RUN.
local NOW = 1794290000
local FILES, GETS, STARTS, CLOCK, GET_AT, PRINT_AT
local _G = {}
local os = { time = function() return NOW + CLOCK end }
local function tick() return CLOCK end
local function isfile(n) return FILES[n] ~= nil end
local function readfile(n)
    if FILES[n] == nil then error("no such file") end
    return FILES[n]
end
local function writefile(n, s) FILES[n] = s end
local delfile = function(n) FILES[n] = nil end
local HttpService = {}
-- Just enough JSON: the note is { at = n, start = b }.
function HttpService:JSONDecode(s)
    if s == "{}" then return {} end
    local at = string.match(s, '"at"%s*:%s*(%d+)')
    local st = string.match(s, '"start"%s*:%s*(%a+)')
    if not at then error("bad json") end
    return { at = tonumber(at), start = st == "true" }
end
local OPTS
local function loadstring(src)
    if OPTS.noCompile then return nil end
    return function()
        local P = { running = false }
        function P.start()
            if OPTS.startFails then error("no mode on") end
            STARTS += 1
            P.running = true
        end
        _G.BFF = P
        if OPTS.selfStart then P.running = true end
    end
end
local function mk(opts)
    OPTS = opts
    FILES, GETS, STARTS, CLOCK, GET_AT, PRINT_AT = {}, {}, 0, 0, nil, {}
    for k in pairs(_G) do _G[k] = nil end
    if opts.bff then _G.BFF = { running = false, start = function() STARTS += 1 end } end
    if opts.flag then
        local at = NOW - (opts.age or 30)
        FILES["bff_crash_resume.json"] = string.format('{"at": %d, "start": %s}', at, tostring(opts.flag.start))
    elseif opts.raw then
        FILES["bff_crash_resume.json"] = opts.raw
    end
    if opts.noDelfile then delfile = nil else delfile = function(n) FILES[n] = nil end end
    local printed = {}
    local loaded = opts.loaded ~= false
    local game = { PlaceId = loaded and opts.place or 0 }
    function game:IsLoaded() return loaded end
    game.Loaded = { Wait = function() loaded = true game.PlaceId = opts.place end }
    function game:GetService(n)
        if n == "HttpService" then return HttpService end
        return nil
    end
    function game:HttpGet(u)
        table.insert(GETS, u)
        GET_AT = CLOCK
        if opts.getFails then error("HttpGet failed") end
        return "-- fast_farm source"
    end
    local task = { wait = function(s) CLOCK += (s or 0.03) end }
    local function pr(s) table.insert(printed, s) table.insert(PRINT_AT, CLOCK) end
    return { game = game, task = task, print = pr, printed = printed }
end
