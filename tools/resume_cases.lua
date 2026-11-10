
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function run(opts)
    local w = mk(opts)
    local ok, err = pcall(RUN, w.game, w.task, w.print)
    w.ok, w.err = ok, err
    return w
end
local SECOND, START = 79091703265657, 2753915549
local FLAG = "bff_crash_resume.json"

-- 1. crashed while farming: fast_farm loaded and started, note used up
local w = run({ place = SECOND, flag = { start = true } })
check("farm was running: loaded", w.ok and #GETS == 1 and _G.BFF ~= nil, tostring(w.err))
check("farm was running: Start pressed once", STARTS == 1, STARTS)
check("note used up", FILES[FLAG] == nil)
check("from fast_farm's own url", string.find(GETS[1] or "", "JodLHarDxD/blox-fast-farm/main/fast_farm.lua", 1, true) ~= nil, GETS[1])
check("says so", w.printed[#w.printed] == "[BFF] crash resume: fast_farm reloaded, farm started again", w.printed[#w.printed])

-- 2. crashed while NOT farming: loaded, no Start
w = run({ place = SECOND, flag = { start = false } })
check("not running: loaded, not started", w.ok and #GETS == 1 and STARTS == 0, STARTS)
check("not running: says press Start", string.find(w.printed[#w.printed] or "", "press Start", 1, true) ~= nil, w.printed[#w.printed])

-- 3. a note from an old crash (over 5 minutes): nothing
w = run({ place = SECOND, flag = { start = true }, age = 400 })
check("stale note: nothing loaded", w.ok and #GETS == 0 and STARTS == 0 and #w.printed == 0, #GETS)

-- 4. no note (a normal launch): nothing
w = run({ place = SECOND })
check("no note: nothing", w.ok and #GETS == 0 and #w.printed == 0, #GETS)

-- 5. any other game: nothing, note left alone
w = run({ place = 12345, flag = { start = true } })
check("other game: nothing", w.ok and #GETS == 0 and FILES[FLAG] ~= nil, #GETS)

-- 6. the start place: waits for the sea's forward before loading
w = run({ place = START, flag = { start = true } })
check("start place: waited 25 s first", w.ok and CLOCK >= 25 and #GETS == 1, CLOCK)

-- 7. fast_farm already there (loaded by hand / a hop's queue): no second copy
w = run({ place = SECOND, flag = { start = true }, bff = true })
check("already loaded: no download, no Start", w.ok and #GETS == 0 and STARTS == 0, #GETS)

-- 8. the loaded copy carried a hunt over and started itself: no second Start
w = run({ place = SECOND, flag = { start = true }, selfStart = true })
check("started by itself: Start not pressed again", w.ok and STARTS == 0, STARTS)
check("started by itself: says already running", string.find(w.printed[#w.printed] or "", "already running", 1, true) ~= nil, w.printed[#w.printed])

-- 9. download fails: a line, no error, note still used up (no loop)
w = run({ place = SECOND, flag = { start = true }, getFails = true })
check("download fails: no error", w.ok, tostring(w.err))
check("download fails: says load by hand", string.find(w.printed[1] or "", "could not be downloaded", 1, true) ~= nil, w.printed[1])
check("download fails: note used up", FILES[FLAG] == nil)
check("a scheduler pass between HttpGet and the print after it", GET_AT and PRINT_AT[1] and PRINT_AT[1] > GET_AT, tostring(GET_AT) .. " " .. tostring(PRINT_AT[1]))

-- 10. does not compile: a line, no error
w = run({ place = SECOND, flag = { start = true }, noCompile = true })
check("no compile: no error, says so", w.ok and string.find(w.printed[1] or "", "did not compile", 1, true) ~= nil, tostring(w.err))

-- 11. Start errors (no mode on): no error out of the file, says so
w = run({ place = SECOND, flag = { start = true }, startFails = true })
check("Start fails: no error, says press it", w.ok and string.find(w.printed[#w.printed] or "", "Start failed", 1, true) ~= nil, w.printed[#w.printed])

-- 12. an executor without delfile: the note is blanked instead
w = run({ place = SECOND, flag = { start = true }, noDelfile = true })
check("no delfile: note blanked, not used twice", w.ok and FILES[FLAG] == "{}" and STARTS == 1, FILES[FLAG])

-- 13. a broken note: nothing, no error
w = run({ place = SECOND, raw = "not json" })
check("broken note: nothing", w.ok and #GETS == 0, tostring(w.err))

-- 14. still loading: the place is read AFTER the load
w = run({ place = SECOND, loaded = false, flag = { start = true } })
check("loading: waits, then resumes", w.ok and #GETS == 1 and STARTS == 1, tostring(w.err))

print(all and "ALL PASS" or "SOME FAILED")
