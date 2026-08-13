--!strict

local FakeClock = {}
FakeClock.__index = FakeClock

export type FakeClock = typeof(setmetatable({} :: {
    _now: number,
}, FakeClock))

function FakeClock.new(startTime: number?): FakeClock
    return setmetatable({
        _now = startTime or 0,
    }, FakeClock)
end

function FakeClock:now(): number
    return self._now
end

function FakeClock:advance(seconds: number): number
    assert(seconds >= 0, "cannot move FakeClock backwards")
    self._now += seconds
    return self._now
end

function FakeClock:set(time: number)
    assert(time >= self._now, "cannot move FakeClock backwards")
    self._now = time
end

return FakeClock
