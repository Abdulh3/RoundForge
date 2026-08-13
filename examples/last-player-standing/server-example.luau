--!strict

-- This example shows where a game-specific elimination system connects to RoundForge.
-- Replace `path.to.RoundForge` with your installed package path.

local RoundForge = require(path.to.RoundForge)

local clock = {
    now = function()
        return workspace:GetServerTimeNow()
    end,
}

local rounds = RoundForge.RoundService.new(clock, {
    minimumPlayers = 2,
    intermissionSeconds = 10,
    preparingSeconds = 3,
    finishedSeconds = 5,
})

local alive: { [number]: boolean } = {}

local function onPlayerReady(player: Player)
    rounds:registerPlayer({
        id = player.UserId,
        name = player.Name,
        payload = player,
    })
end

local function onPlayerLeaving(player: Player)
    alive[player.UserId] = nil
    rounds:unregisterPlayer(player.UserId)
end

local function beginGameSpecificRound()
    table.clear(alive)
    for _, participant in rounds:getParticipants():getRoundParticipants() do
        alive[participant.id :: number] = true
    end
end

local function eliminate(userId: number)
    alive[userId] = nil

    local remaining = {}
    for id in alive do
        table.insert(remaining, id)
    end

    if #remaining <= 1 and rounds:getSnapshot().state == "Playing" then
        rounds:finish(remaining[1])
    end
end

-- Your own scheduler should call rounds:tick() and detect the transition into Playing.
-- At that point call beginGameSpecificRound().
-- Your game mechanic calls eliminate(userId) as players are removed.

return {
    onPlayerReady = onPlayerReady,
    onPlayerLeaving = onPlayerLeaving,
    beginGameSpecificRound = beginGameSpecificRound,
    eliminate = eliminate,
    rounds = rounds,
}
