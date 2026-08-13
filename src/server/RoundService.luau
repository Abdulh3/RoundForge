--!strict

export type Clock = {
    now: (self: any) -> number,
}

export type Config = {
    minimumPlayers: number?,
    intermissionSeconds: number?,
    preparingSeconds: number?,
    finishedSeconds: number?,
}

export type Dependencies = {
    StateMachine: any,
    ParticipantService: any,
}

local TRANSITIONS = {
    Waiting = { Intermission = true },
    Intermission = { Waiting = true, Preparing = true },
    Preparing = { Waiting = true, Playing = true },
    Playing = { Finished = true, Waiting = true },
    Finished = { Waiting = true },
}

local RoundService = {}
RoundService.__index = RoundService

export type RoundService = typeof(setmetatable({} :: {
    _clock: Clock,
    _participants: any,
    _machine: any,
    _minimumPlayers: number,
    _intermissionSeconds: number,
    _preparingSeconds: number,
    _finishedSeconds: number,
    _deadline: number?,
    _roundId: number,
    _winnerId: (number | string)?,
}, RoundService))

local function resolveDependencies(overrides: Dependencies?): Dependencies
    if overrides ~= nil then
        assert(overrides.StateMachine ~= nil, "dependencies.StateMachine is required")
        assert(overrides.ParticipantService ~= nil, "dependencies.ParticipantService is required")
        return overrides
    end

    -- Roblox path. Standalone deterministic tests inject the same modules
    -- explicitly, so the production source remains the source under test.
    return {
        StateMachine = require(script.Parent.Parent.shared.StateMachine),
        ParticipantService = require(script.Parent.ParticipantService),
    }
end

local function assertFiniteNonNegative(value: number, name: string)
    assert(
        value >= 0 and value < math.huge,
        name .. " must be a finite non-negative number"
    )
end

function RoundService.new(clock: Clock, config: Config?, dependencyOverrides: Dependencies?): RoundService
    assert(clock ~= nil and type(clock.now) == "function", "clock with now() is required")

    local dependencies = resolveDependencies(dependencyOverrides)
    local resolved = config or {}
    local minimumPlayers = resolved.minimumPlayers or 2
    local intermissionSeconds = resolved.intermissionSeconds or 10
    local preparingSeconds = resolved.preparingSeconds or 3
    local finishedSeconds = resolved.finishedSeconds or 5

    assert(
        minimumPlayers >= 1 and minimumPlayers % 1 == 0,
        "minimumPlayers must be a positive integer"
    )
    assertFiniteNonNegative(intermissionSeconds, "intermissionSeconds")
    assertFiniteNonNegative(preparingSeconds, "preparingSeconds")
    assertFiniteNonNegative(finishedSeconds, "finishedSeconds")

    return setmetatable({
        _clock = clock,
        _participants = dependencies.ParticipantService.new(),
        _machine = dependencies.StateMachine.new("Waiting", TRANSITIONS),
        _minimumPlayers = minimumPlayers,
        _intermissionSeconds = intermissionSeconds,
        _preparingSeconds = preparingSeconds,
        _finishedSeconds = finishedSeconds,
        _deadline = nil,
        _roundId = 0,
        _winnerId = nil,
    }, RoundService)
end

function RoundService:registerPlayer(participant: any)
    self._participants:connect(participant)
end

function RoundService:unregisterPlayer(id: number | string)
    self._participants:disconnect(id)

    if self._winnerId == id then
        self._winnerId = nil
    end

    local state = self._machine:getState()

    if state == "Intermission" then
        if self._participants:connectedCount() < self._minimumPlayers then
            self:_abortToWaiting()
        end
    elseif state == "Preparing" or state == "Playing" then
        if self._participants:roundCount() < self._minimumPlayers then
            self:_abortToWaiting()
        end
    end
end

function RoundService:start()
    self:tick()
end

function RoundService:reset()
    self:_abortToWaiting()
end

function RoundService:_setDeadline(seconds: number?)
    self._deadline = if seconds == nil then nil else self._clock:now() + seconds
end

function RoundService:_abortToWaiting()
    local state = self._machine:getState()

    if state ~= "Waiting" then
        self._machine:transition("Waiting")
    end

    self._participants:unlockRound()
    self._winnerId = nil
    self:_setDeadline(nil)
end

function RoundService:_enterIntermission()
    self._machine:transition("Intermission")
    self:_setDeadline(self._intermissionSeconds)
end

function RoundService:_enterPreparing()
    local participantSnapshot = self._participants:lockRound()

    if #participantSnapshot < self._minimumPlayers then
        self:_abortToWaiting()
        return
    end

    self._roundId += 1
    self._winnerId = nil
    self._machine:transition("Preparing")
    self:_setDeadline(self._preparingSeconds)
end

function RoundService:_enterPlaying()
    self._machine:transition("Playing")
    self:_setDeadline(nil)
end

function RoundService:finish(winnerId: (number | string)?)
    assert(
        self._machine:getState() == "Playing",
        "finish can only be called while Playing"
    )

    if winnerId ~= nil then
        assert(
            self._participants:isRoundParticipant(winnerId),
            "winner must belong to the active round participant snapshot"
        )
    end

    self._winnerId = winnerId
    self._machine:transition("Finished")
    self:_setDeadline(self._finishedSeconds)
end

function RoundService:tick()
    local state = self._machine:getState()

    if state == "Waiting" then
        if self._participants:connectedCount() >= self._minimumPlayers then
            self:_enterIntermission()
        end
        return
    end

    if state == "Intermission" then
        if self._participants:connectedCount() < self._minimumPlayers then
            self:_abortToWaiting()
            return
        end
    elseif state == "Preparing" or state == "Playing" then
        -- Late joiners must never keep a dying locked round alive.
        if self._participants:roundCount() < self._minimumPlayers then
            self:_abortToWaiting()
            return
        end
    end

    if self._deadline == nil or self._clock:now() < self._deadline then
        return
    end

    if state == "Intermission" then
        self:_enterPreparing()
    elseif state == "Preparing" then
        self:_enterPlaying()
    elseif state == "Finished" then
        self:_abortToWaiting()
    end
end

function RoundService:getSnapshot()
    local state = self._machine:getState()
    local remaining = nil

    if self._deadline ~= nil then
        remaining = math.max(0, self._deadline - self._clock:now())
    end

    return {
        roundId = self._roundId,
        state = state,
        deadline = self._deadline,
        remaining = remaining,
        minimumPlayers = self._minimumPlayers,
        connectedCount = self._participants:connectedCount(),
        roundCount = self._participants:roundCount(),
        lateJoinerCount = self._participants:lateJoinerCount(),
        roundLocked = self._participants:isRoundLocked(),
        winnerId = self._winnerId,
        connectedIds = self._participants:getConnectedIds(),
        roundParticipantIds = self._participants:getRoundParticipantIds(),
        lateJoinerIds = self._participants:getLateJoinerIds(),
        history = self._machine:getHistory(),
    }
end

function RoundService:getParticipants(): any
    return self._participants
end

return RoundService
