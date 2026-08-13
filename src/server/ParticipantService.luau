--!strict

export type Participant = {
    id: number | string,
    name: string?,
    payload: any?,
}

local ParticipantService = {}
ParticipantService.__index = ParticipantService

export type ParticipantService = typeof(setmetatable({} :: {
    _connected: { [number | string]: Participant },
    _roundParticipants: { [number | string]: Participant },
    _lateJoiners: { [number | string]: Participant },
    _roundLocked: boolean,
}, ParticipantService))

function ParticipantService.new(): ParticipantService
    return setmetatable({
        _connected = {},
        _roundParticipants = {},
        _lateJoiners = {},
        _roundLocked = false,
    }, ParticipantService)
end

function ParticipantService:connect(participant: Participant)
    assert(participant.id ~= nil, "participant.id is required")
    self._connected[participant.id] = participant

    if self._roundLocked and self._roundParticipants[participant.id] == nil then
        self._lateJoiners[participant.id] = participant
    end
end

function ParticipantService:disconnect(id: number | string)
    self._connected[id] = nil
    self._roundParticipants[id] = nil
    self._lateJoiners[id] = nil
end

function ParticipantService:lockRound(): { Participant }
    table.clear(self._roundParticipants)
    table.clear(self._lateJoiners)

    for id, participant in self._connected do
        self._roundParticipants[id] = participant
    end

    self._roundLocked = true
    return self:getRoundParticipants()
end

function ParticipantService:unlockRound()
    self._roundLocked = false
    table.clear(self._roundParticipants)
    table.clear(self._lateJoiners)
end

function ParticipantService:isRoundLocked(): boolean
    return self._roundLocked
end

function ParticipantService:isRoundParticipant(id: number | string): boolean
    return self._roundParticipants[id] ~= nil
end

function ParticipantService:isLateJoiner(id: number | string): boolean
    return self._lateJoiners[id] ~= nil
end

function ParticipantService:getConnected(): { Participant }
    local result = {}
    for _, participant in self._connected do
        table.insert(result, participant)
    end
    return result
end

function ParticipantService:getRoundParticipants(): { Participant }
    local result = {}
    for _, participant in self._roundParticipants do
        table.insert(result, participant)
    end
    return result
end

function ParticipantService:getLateJoiners(): { Participant }
    local result = {}
    for _, participant in self._lateJoiners do
        table.insert(result, participant)
    end
    return result
end

function ParticipantService:connectedCount(): number
    local count = 0
    for _ in self._connected do
        count += 1
    end
    return count
end

function ParticipantService:roundCount(): number
    local count = 0
    for _ in self._roundParticipants do
        count += 1
    end
    return count
end

return ParticipantService
