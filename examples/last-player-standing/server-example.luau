--!strict

-- Place the RoundForge package as ServerScriptService.RoundForge, then place
-- this Script beside it. This intentionally contains no map/weapon logic; it
-- demonstrates the complete round lifecycle and elimination boundary.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local RoundForge = require(ServerScriptService:WaitForChild("RoundForge"))

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
local lastState = rounds:getSnapshot().state

local function aliveIds(): { number }
    local result = {}

    for userId in alive do
        table.insert(result, userId)
    end

    table.sort(result)
    return result
end

local function checkForWinner()
    if rounds:getSnapshot().state ~= "Playing" then
        return
    end

    local remaining = aliveIds()

    if #remaining <= 1 then
        rounds:finish(remaining[1])
    end
end

local function eliminate(userId: number)
    if alive[userId] ~= true then
        return
    end

    alive[userId] = nil
    checkForWinner()
end

local function watchCharacter(player: Player, character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid") :: Humanoid

    humanoid.Died:Connect(function()
        eliminate(player.UserId)
    end)
end

local function registerPlayer(player: Player)
    rounds:registerPlayer({
        id = player.UserId,
        name = player.Name,
        payload = player,
    })

    player.CharacterAdded:Connect(function(character)
        watchCharacter(player, character)
    end)

    if player.Character ~= nil then
        watchCharacter(player, player.Character)
    end
end

local function unregisterPlayer(player: Player)
    alive[player.UserId] = nil
    rounds:unregisterPlayer(player.UserId)
    checkForWinner()
end

local function beginRound()
    table.clear(alive)

    for _, participant in rounds:getParticipants():getRoundParticipants() do
        alive[participant.id :: number] = true
    end

    print(string.format(
        "[RoundForge example] round %d started with %d players",
        rounds:getSnapshot().roundId,
        #aliveIds()
    ))
end

local function onStateChanged(previous: string, current: string)
    print(string.format("[RoundForge example] %s -> %s", previous, current))

    if current == "Playing" then
        beginRound()
    elseif current == "Waiting" then
        table.clear(alive)
    elseif current == "Finished" then
        print("[RoundForge example] winner:", rounds:getSnapshot().winnerId)
    end
end

for _, player in Players:GetPlayers() do
    registerPlayer(player)
end

Players.PlayerAdded:Connect(registerPlayer)
Players.PlayerRemoving:Connect(unregisterPlayer)

RunService.Heartbeat:Connect(function()
    rounds:tick()

    local currentState = rounds:getSnapshot().state
    if currentState ~= lastState then
        local previousState = lastState
        lastState = currentState
        onStateChanged(previousState, currentState)
    end
end)
