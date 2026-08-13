--!strict

export type ParticipantId = number | string

export type Participant = {
    id: ParticipantId,
    name: string?,
    payload: any?,
}

local ParticipantService = {}
ParticipantService.__index = ParticipantService

export type ParticipantService = typeof(setmetatable({} :: {
    _connected: { [ParticipantId]: Participant },
    _roundParticipants: { [ParticipantId]: Participant },
    _lateJoiners: { [ParticipantId]: Participant },
    _roundLocked: boolean,
}, ParticipantService))

local function sortedIds(source: { [ParticipantId]: any }): { ParticipantId }
    local result = {}

    for id in source do
        table.insert(result, id)
    end

    table.sort(result, function(a, b)
        local typeA = type(a)
        local typeB = type(b)

        if typeA ~= typeB then
            return typeA < typeB
        end

        if typeA == "number" then
            return (a :: number) < (b :: number)
        end

        return tostring(a) < tostring(b)
    end)

    return result
end

local function valuesInIdOrder(source: { [ParticipantId]: Participant }): { Participant }
    local result = {}

    for _, id in sortedIds(source) do
        table.insert(result, source[id])
    end

    return result
end

local function countMap(source: { [ParticipantId]: any }): number
    local count = 0

    for _ in source do
        count += 1
    end

    return count
end

function ParticipantService.new(): ParticipantService
    return setmetatable({
        _connected = {},
        _roundParticipants = {},
        _lateJoiners = {},
        _roundLocked = false,
    }, ParticipantService)
end

function ParticipantService:connect(participant: Participant)
    assert(participant ~= nil, "participant is required")
    assert(
        type(participant.id) == "number" or type(participant.id) == "string",
        "participant.id must be a number or string"
    )

    local id = participant.id
    self._connected[id] = participant

    if self._roundLocked then
        if self._roundParticipants[id] ~= nil then
            -- Replace the payload/reference for the same logical participant
            -- without changing membership in the locked snapshot.
            self._roundParticipants[id] = participant
        else
            self._lateJoiners[id] = participant
        end
    end
end

function ParticipantService:disconnect(id: ParticipantId)
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

function ParticipantService:isConnected(id: ParticipantId): boolean
    return self._connected[id] ~= nil
end

function ParticipantService:isRoundParticipant(id: ParticipantId): boolean
    return self._roundParticipants[id] ~= nil
end

function ParticipantService:isLateJoiner(id: ParticipantId): boolean
    return self._lateJoiners[id] ~= nil
end

function ParticipantService:getParticipant(id: ParticipantId): Participant?
    return self._connected[id]
end

function ParticipantService:getConnected(): { Participant }
    return valuesInIdOrder(self._connected)
end

function ParticipantService:getRoundParticipants(): { Participant }
    return valuesInIdOrder(self._roundParticipants)
end

function ParticipantService:getLateJoiners(): { Participant }
    return valuesInIdOrder(self._lateJoiners)
end

function ParticipantService:getConnectedIds(): { ParticipantId }
    return sortedIds(self._connected)
end

function ParticipantService:getRoundParticipantIds(): { ParticipantId }
    return sortedIds(self._roundParticipants)
end

function ParticipantService:getLateJoinerIds(): { ParticipantId }
    return sortedIds(self._lateJoiners)
end

function ParticipantService:connectedCount(): number
    return countMap(self._connected)
end

function ParticipantService:roundCount(): number
    return countMap(self._roundParticipants)
end

function ParticipantService:lateJoinerCount(): number
    return countMap(self._lateJoiners)
end

return ParticipantService
