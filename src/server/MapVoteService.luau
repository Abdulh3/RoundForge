--!strict

export type VoteResult = {
    winner: string?,
    counts: { [string]: number },
    tied: { string },
}

local MapVoteService = {}
MapVoteService.__index = MapVoteService

export type MapVoteService = typeof(setmetatable({} :: {
    _options: { string },
    _validOptions: { [string]: boolean },
    _votesByPlayer: { [number | string]: string },
    _locked: boolean,
}, MapVoteService))

function MapVoteService.new(options: { string }): MapVoteService
    local self = setmetatable({
        _options = table.clone(options),
        _validOptions = {},
        _votesByPlayer = {},
        _locked = false,
    }, MapVoteService)

    for _, option in options do
        assert(option ~= "", "map option must not be empty")
        assert(not self._validOptions[option], "duplicate map option: " .. option)
        self._validOptions[option] = true
    end

    return self
end

function MapVoteService:vote(playerId: number | string, option: string): boolean
    if self._locked or not self._validOptions[option] then
        return false
    end

    self._votesByPlayer[playerId] = option
    return true
end

function MapVoteService:removePlayer(playerId: number | string)
    self._votesByPlayer[playerId] = nil
end

function MapVoteService:lock()
    self._locked = true
end

function MapVoteService:isLocked(): boolean
    return self._locked
end

function MapVoteService:getCounts(): { [string]: number }
    local counts = {}
    for _, option in self._options do
        counts[option] = 0
    end

    for _, option in self._votesByPlayer do
        counts[option] += 1
    end

    return counts
end

function MapVoteService:resolve(randomIndex: ((number) -> number)?): VoteResult
    local counts = self:getCounts()
    local bestCount = -1
    local tied = {}

    for _, option in self._options do
        local count = counts[option]
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
        local index = randomIndex and randomIndex(#tied) or 1
        assert(index >= 1 and index <= #tied, "randomIndex returned an invalid index")
        winner = tied[index]
    end

    return {
        winner = winner,
        counts = counts,
        tied = tied,
    }
end

function MapVoteService:reset(options: { string }?)
    if options then
        self._options = table.clone(options)
        table.clear(self._validOptions)
        for _, option in options do
            self._validOptions[option] = true
        end
    end

    table.clear(self._votesByPlayer)
    self._locked = false
end

return MapVoteService
