
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
local THIRD, FIRST = 100117331123089, 2753915549

-- 1. a Blox Fruits join with no team: SetTeam Pirates until you are on it
local w = run({ place = THIRD, joinAfter = 2 })
check("asks for Pirates until on it", w.ok and table.concat(w.calls, ",") == "SetTeam:Pirates,SetTeam:Pirates",
    table.concat(w.calls, ",") .. " " .. tostring(w.err))
check("says so", w.printed[1] == "[BFF] autoexec team: on Pirates", w.printed[1])
check("team screen hidden", w.player.PlayerGui.Main.ChooseTeam.Visible == false)

-- 2. any other game: nothing
w = run({ place = 12345, joinAfter = 1 })
check("other game: no call, no print", w.ok and #w.calls == 0 and #w.printed == 0, #w.calls)

-- 3. already on a team: never switched
w = run({ place = FIRST, team = { Name = "Marines" }, joinAfter = 1 })
check("on a team already: no call", w.ok and #w.calls == 0 and w.player.Team.Name == "Marines", #w.calls)

-- 4. the game never takes it: stops after a minute, no endless loop
w = run({ place = THIRD })
check("gives up after 30 tries (~1 min)", w.ok and #w.calls == 30 and w.clock() <= 61, #w.calls .. " " .. w.clock())
check("no 'on' line when it failed", #w.printed == 0)

-- 5. still loading: the place is read AFTER the load, not the 0 before it
w = run({ place = THIRD, loaded = false, joinAfter = 1 })
check("loading: waits, then picks", w.ok and #w.calls == 1, #w.calls .. " " .. tostring(w.err))

-- 6. no Remotes (a game update moved them): out quietly, no error
w = run({ place = THIRD, noRemotes = true })
check("no remotes: no error, no call", w.ok and #w.calls == 0, tostring(w.err))

-- 7. the remote errors once (throttled): it keeps asking
w = run({ place = THIRD, errorFirst = true, joinAfter = 2 })
check("a call error does not end it", w.ok and #w.calls == 2 and w.player.Team ~= nil, tostring(w.err))

print(all and "ALL PASS" or "SOME FAILED")
