
-- What autoexec_team.lua touches, faked. mk(opts) builds one join:
--   place      the PlaceId once loaded
--   loaded     false = the game is still loading (PlaceId 0 until Loaded)
--   team       the team you are already on (nil = none)
--   joinAfter  the SetTeam call that puts you on the team (nil = never)
--   noRemotes  ReplicatedStorage has no Remotes
--   errorFirst the first SetTeam call errors (throttled)
-- The file runs as RUN(game, task, print); its `return`s end RUN.
local function mk(opts)
    local calls, printed = {}, {}
    local clock = 0
    local player = { Team = opts.team, PlayerGui = { Main = { ChooseTeam = { Visible = true } } } }
    local cf = {}
    function cf:InvokeServer(a, b)
        table.insert(calls, a .. ":" .. tostring(b))
        if opts.errorFirst and #calls == 1 then error("InvokeServer throttled") end
        if opts.joinAfter and #calls >= opts.joinAfter then player.Team = { Name = b } end
    end
    local remotes = nil
    if not opts.noRemotes then
        remotes = { CommF_ = cf }
        function remotes:WaitForChild(n) return self[n] end
    end
    local RS = {}
    function RS:WaitForChild(n) if n == "Remotes" then return remotes end return nil end
    local loaded = opts.loaded ~= false
    local game = { PlaceId = loaded and opts.place or 0 }
    function game:IsLoaded() return loaded end
    game.Loaded = { Wait = function() loaded = true game.PlaceId = opts.place end }
    function game:GetService(n)
        if n == "Players" then return { LocalPlayer = player } end
        if n == "ReplicatedStorage" then return RS end
        return nil
    end
    local task = { wait = function(s) clock += (s or 0.03) end }
    local function pr(s) table.insert(printed, s) end
    return {
        game = game, task = task, print = pr, calls = calls, printed = printed,
        player = player, clock = function() return clock end,
    }
end
