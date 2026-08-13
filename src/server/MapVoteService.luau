--!strict

export type ParticipantId = number | string

export type VoteResult = {
    winner: string?,
    counts: { [string]: number },
    tied: { string },
    totalVotes: number,
}

local MapVoteService = {}
MapVoteService.__index = MapVoteService

export type MapVoteService = typeof(setmetatable({} :: {
    _options: { string },
    _validOptions: { [string]: boolean },
    _votesByPlayer: { [ParticipantId]: string },
    _locked: boolean,
}, MapVoteService))

local function validateOptions(options: { string })
    local seen = {}

    for _, option in options do
        assert(type(option) == "string" and option ~= "", "map option must be a non-empty string")
        assert(not seen[option], "duplicate map option: " .. option)
        seen[option] = true
    end
end

function MapVoteService.new(options: { string }): MapVoteService
    validateOptions(options)

    local self = setmetatable({
        _options = {},
        _validOptions = {},
        _votesByPlayer = {},
        _locked = false,
    }, MapVoteService)

    self:_setOptions(options)
    return self
end

function MapVoteService:_setOptions(options: { string })
    validateOptions(options)

    self._options = table.clone(options)
    table.clear(self._validOptions)

    for _, option in options do
        self._validOptions[option] = true
    end
end

function MapVoteService:vote(playerId: ParticipantId, option: string): boolean
    if self._locked or not self._validOptions[option] then
        return false
    end

    self._votesByPlayer[playerId] = option
    return true
end

function MapVoteService:removePlayer(playerId: ParticipantId)
    self._votesByPlayer[playerId] = nil
end

function MapVoteService:lock()
    self._locked = true
end

function MapVoteService:isLocked(): boolean
    return self._locked
end

function MapVoteService:getOptions(): { string }
    return table.clone(self._options)
end

function MapVoteService:getVotes(): { [ParticipantId]: string }
    return table.clone(self._votesByPlayer)
end

function MapVoteService:getCounts(): { [string]: number }
    local counts = {}

    for _, option in self._options do
        counts[option] = 0
    end

    for _, option in self._votesByPlayer do
        if counts[option] ~= nil then
            counts[option] += 1
        end
    end

    return counts
end

function MapVoteService:resolve(pickIndex: ((number) -> number)?): VoteResult
    local counts = self:getCounts()
    local bestCount = -1
    local totalVotes = 0
    local tied = {}

    for _, option in self._options do
        local count = counts[option]
        totalVotes += count

        if count > bestCount then
            bestCount = count
            table.clear(tied)
            table.insert(tied, option)
        elseif count == bestCount then
            table.insert(tied, option)
        end
    end

    local winner = nil

    if #tied > 0 then
        -- The default is deterministic. Production games can inject a seeded
        -- or random chooser; tests can inject a predictable chooser.
        local index = if pickIndex ~= nil then pickIndex(#tied) else 1
        assert(index >= 1 and index <= #tied and index % 1 == 0, "pickIndex returned an invalid index")
        winner = tied[index]
    end

    return {
        winner = winner,
        counts = counts,
        tied = table.clone(tied),
        totalVotes = totalVotes,
    }
end

function MapVoteService:reset(options: { string }?)
    if options ~= nil then
        self:_setOptions(options)
    end

    table.clear(self._votesByPlayer)
    self._locked = false
end

return MapVoteService
