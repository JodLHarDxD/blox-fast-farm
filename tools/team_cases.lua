
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

reset()
P.pickTeam()
check("no team: SetTeam Pirates, on it, screen closed", table.concat(CALLS, ",") == "SetTeam Pirates"
    and player.Team.Name == "Pirates" and P.teamNote == "on Pirates" and screen.Visible == false,
    table.concat(CALLS, ","))

reset() REMOTE_WORKS = false BUTTON_WORKS = true
P.pickTeam()
local fired = false
for _, c in ipairs(CALLS) do if c:find("button", 1, true) then fired = true end end
check("remote ignored: asked again, the screen's button NEVER fired (crash risk)",
    not fired and #CALLS > 1 and player.Team == nil, table.concat(CALLS, ","))

reset() CFG.Team = "Marines"
P.pickTeam()
check("Marines picked: Marines asked for", table.concat(CALLS, ",") == "SetTeam Marines"
    and player.Team.Name == "Marines", table.concat(CALLS, ","))

reset() player.Team = { Name = "Marines" }
P.pickTeam()
check("already on a team: nothing sent, never switched", #CALLS == 0 and player.Team.Name == "Marines")

reset() CFG.AutoTeam = false
P.pickTeam()
check("picking off: nothing sent, says so", #CALLS == 0 and player.Team == nil
    and P.teamNote:find("off", 1, true) ~= nil, P.teamNote)

reset() REMOTE_WORKS = false BUTTON_WORKS = false
P.pickTeam()
check("nothing works: keeps asking, says so, no switch", #CALLS > 2 and player.Team == nil
    and P.teamNote:find("asking for Pirates", 1, true) ~= nil, P.teamNote)

-- YOUR PICK IS KEPT (user, 2026-10-24: Marines picked, every hop joined Pirates)
local FILE = "bff_team_42.json"
reset() FILES[FILE] = { team = "Marines", pick = true }
P.pickTeam()
check("kept Marines over this load's Pirates: Marines asked for, CFG follows",
    table.concat(CALLS, ",") == "SetTeam Marines" and CFG.Team == "Marines", table.concat(CALLS, ","))

reset() FILES[FILE] = { team = "Marines", pick = false }
P.pickTeam()
check("kept pick off: nothing sent", #CALLS == 0 and CFG.AutoTeam == false, #CALLS)

reset() CFG.Team = "Marines"
P.pickTeam()
check("nothing kept yet: this load's team is kept (for the autoexec)",
    type(FILES[FILE]) == "table" and FILES[FILE].team == "Marines" and FILES[FILE].pick == true,
    FILES[FILE] and FILES[FILE].team)

reset() FILES[FILE] = { team = "Navy" }
P.pickTeam()
check("a kept file with no team: this load's, and kept over it",
    table.concat(CALLS, ",") == "SetTeam Pirates" and FILES[FILE].team == "Pirates", table.concat(CALLS, ","))

reset() CFG.Team = "Marines" CFG.AutoTeam = false
P.teamSave()
check("the panel's change is kept", FILES[FILE].team == "Marines" and FILES[FILE].pick == false)

print(all and "ALL PASS" or "SOME FAILED")
