--!strict

export type Dependencies = {
    Invariants: any,
    Reporter: any,
}

local TestHarness = {}
TestHarness.__index = TestHarness

export type TestHarness = typeof(setmetatable({} :: {
    _round: any,
    _clock: any,
    _scenario: string,
    _seed: number?,
    _checkpoints: { any },
    _invariants: any,
    _reporter: any,
}, TestHarness))

local function resolveDependencies(overrides: Dependencies?): Dependencies
    if overrides ~= nil then
        assert(overrides.Invariants ~= nil, "dependencies.Invariants is required")
        assert(overrides.Reporter ~= nil, "dependencies.Reporter is required")
        return overrides
    end

    return {
        Invariants = require(script.Parent.Invariants),
        Reporter = require(script.Parent.Reporter),
    }
end

function TestHarness.new(
    scenario: string,
    roundService: any,
    clock: any,
    dependencyOverrides: Dependencies?,
    seed: number?
): TestHarness
    assert(scenario ~= "", "scenario name must not be empty")
    assert(roundService ~= nil, "roundService is required")
    assert(clock ~= nil, "clock is required")

    local dependencies = resolveDependencies(dependencyOverrides)

    return setmetatable({
        _round = roundService,
        _clock = clock,
        _scenario = scenario,
        _seed = seed,
        _checkpoints = {},
        _invariants = dependencies.Invariants,
        _reporter = dependencies.Reporter,
    }, TestHarness)
end

function TestHarness:checkpoint(label: string)
    local snapshot = self._round:getSnapshot()
    local checks = self._invariants.runCore(snapshot)

    table.insert(self._checkpoints, {
        label = label,
        at = self._clock:now(),
        snapshot = snapshot,
        checks = checks,
    })

    return snapshot
end

function TestHarness:expect(label: string, passed: boolean, message: string?)
    local snapshot = self._round:getSnapshot()

    table.insert(self._checkpoints, {
        label = label,
        at = self._clock:now(),
        snapshot = snapshot,
        checks = {
            {
                name = label,
                passed = passed,
                message = if passed then nil else message or "expectation failed",
            },
        },
    })

    return snapshot
end

function TestHarness:connect(id: number | string, name: string?)
    self._round:registerPlayer({
        id = id,
        name = name or tostring(id),
    })
end

function TestHarness:disconnect(id: number | string)
    self._round:unregisterPlayer(id)
end

function TestHarness:tick()
    self._round:tick()
end

function TestHarness:advance(seconds: number)
    self._clock:advance(seconds)
    self._round:tick()
end

function TestHarness:advanceToDeadline()
    local snapshot = self._round:getSnapshot()
    assert(snapshot.deadline ~= nil, "current state has no deadline")

    self._clock:set(snapshot.deadline)
    self._round:tick()
end

function TestHarness:runToState(targetState: string, maxTransitions: number?)
    local maxSteps = maxTransitions or 10

    for _ = 1, maxSteps do
        local snapshot = self._round:getSnapshot()

        if snapshot.state == targetState then
            return snapshot
        end

        if snapshot.state == "Waiting" then
            self._round:tick()
        else
            assert(
                snapshot.deadline ~= nil,
                "cannot auto-advance a state without a deadline"
            )
            self:advanceToDeadline()
        end
    end

    error(
        "failed to reach state " .. targetState .. " within transition budget",
        2
    )
end

function TestHarness:finish(winnerId: (number | string)?)
    self._round:finish(winnerId)
end

function TestHarness:getCheckpoints(): { any }
    return table.clone(self._checkpoints)
end

function TestHarness:report()
    return self._reporter.fromCheckpoints(
        self._scenario,
        self._checkpoints,
        self._seed
    )
end

return TestHarness
