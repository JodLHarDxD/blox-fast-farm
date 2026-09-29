
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
check("remote ignored: the screen's own Pirates button", table.concat(CALLS, ",") == "SetTeam Pirates,button Pirates"
    and player.Team.Name == "Pirates", table.concat(CALLS, ","))

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

print(all and "ALL PASS" or "SOME FAILED")
