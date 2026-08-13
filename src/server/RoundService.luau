--!strict

local StateMachine = require(script.Parent.Parent.shared.StateMachine)
local ParticipantService = require(script.Parent.ParticipantService)

export type Clock = {
    now: (self: any) -> number,
}

export type Config = {
    minimumPlayers: number?,
    intermissionSeconds: number?,
    preparingSeconds: number?,
    finishedSeconds: number?,
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
    _participants: ParticipantService.ParticipantService,
    _machine: StateMachine.StateMachine,
    _minimumPlayers: number,
    _intermissionSeconds: number,
    _preparingSeconds: number,
    _finishedSeconds: number,
    _deadline: number?,
    _roundId: number,
    _winnerId: (number | string)?,
}, RoundService))

function RoundService.new(clock: Clock, config: Config?): RoundService
    local resolved = config or {}

    return setmetatable({
        _clock = clock,
        _participants = ParticipantService.new(),
        _machine = StateMachine.new("Waiting", TRANSITIONS),
        _minimumPlayers = resolved.minimumPlayers or 2,
        _intermissionSeconds = resolved.intermissionSeconds or 10,
        _preparingSeconds = resolved.preparingSeconds or 3,
        _finishedSeconds = resolved.finishedSeconds or 5,
        _deadline = nil,
        _roundId = 0,
        _winnerId = nil,
    }, RoundService)
end

function RoundService:registerPlayer(participant: ParticipantService.Participant)
    self._participants:connect(participant)
end

function RoundService:unregisterPlayer(id: number | string)
    self._participants:disconnect(id)

    if self._winnerId == id then
        self._winnerId = nil
    end

    if self._machine:getState() ~= "Waiting" and self._participants:connectedCount() < self._minimumPlayers then
        self:_abortToWaiting()
    end
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
    self._participants:lockRound()
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
    assert(self._machine:getState() == "Playing", "finish can only be called while Playing")

    if winnerId ~= nil then
        assert(self._participants:isRoundParticipant(winnerId), "winner must belong to the round participant snapshot")
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

    if self._participants:connectedCount() < self._minimumPlayers then
        self:_abortToWaiting()
        return
    end

    if self._deadline == nil or self._clock:now() < self._deadline then
        return
    end

    if state == "Intermission" then
        self:_enterPreparing()
    elseif state == "Preparing" then
        if self._participants:roundCount() < self._minimumPlayers then
            self:_abortToWaiting()
        else
            self:_enterPlaying()
        end
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
        connectedCount = self._participants:connectedCount(),
        roundCount = self._participants:roundCount(),
        roundLocked = self._participants:isRoundLocked(),
        winnerId = self._winnerId,
        history = self._machine:getHistory(),
    }
end

function RoundService:getParticipants(): ParticipantService.ParticipantService
    return self._participants
end

return RoundService
