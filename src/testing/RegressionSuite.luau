--!strict

export type Dependencies = {
    FakeClock: any,
    Reporter: any,
    TestHarness: any,
    RoundService: any,
    MapVoteService: any,
    StateMachine: any,
    ParticipantService: any,
    Invariants: any,
}

local RegressionSuite = {}

local function resolveDependencies(overrides: Dependencies?): Dependencies
    if overrides ~= nil then
        return overrides
    end

    return {
        FakeClock = require(script.Parent.FakeClock),
        Reporter = require(script.Parent.Reporter),
        TestHarness = require(script.Parent.TestHarness),
        RoundService = require(script.Parent.Parent.server.RoundService),
        MapVoteService = require(script.Parent.Parent.server.MapVoteService),
        StateMachine = require(script.Parent.Parent.shared.StateMachine),
        ParticipantService = require(script.Parent.Parent.server.ParticipantService),
        Invariants = require(script.Parent.Invariants),
    }
end

local function roundDependencies(dependencies: Dependencies)
    return {
        StateMachine = dependencies.StateMachine,
        ParticipantService = dependencies.ParticipantService,
    }
end

local function harnessDependencies(dependencies: Dependencies)
    return {
        Invariants = dependencies.Invariants,
        Reporter = dependencies.Reporter,
    }
end

local function basicRound(dependencies: Dependencies)
    local clock = dependencies.FakeClock.new()
    local round = dependencies.RoundService.new(
        clock,
        {
            minimumPlayers = 2,
            intermissionSeconds = 10,
            preparingSeconds = 3,
            finishedSeconds = 2,
        },
        roundDependencies(dependencies)
    )
    local harness = dependencies.TestHarness.new(
        "basic-round",
        round,
        clock,
        harnessDependencies(dependencies)
    )

    harness:checkpoint("initial")
    harness:connect(1, "Alpha")
    harness:connect(2, "Bravo")
    harness:runToState("Playing")
    local playing = harness:checkpoint("playing")

    harness:expect(
        "locked-two-player-snapshot",
        playing.roundLocked == true and playing.roundCount == 2,
        "expected exactly two locked participants"
    )

    harness:finish(1)
    local finished = harness:checkpoint("finished")
    harness:expect(
        "winner-recorded",
        finished.winnerId == 1,
        "winner should be participant 1"
    )

    harness:advanceToDeadline()
    local waiting = harness:checkpoint("reset-to-waiting")
    harness:expect(
        "cleanup-after-finish",
        waiting.state == "Waiting"
            and waiting.roundCount == 0
            and waiting.lateJoinerCount == 0
            and waiting.winnerId == nil,
        "round residue remained after Finished -> Waiting"
    )

    return harness:report()
end

local function lateJoinLifecycle(dependencies: Dependencies)
    local clock = dependencies.FakeClock.new()
    local round = dependencies.RoundService.new(
        clock,
        {
            minimumPlayers = 2,
            intermissionSeconds = 2,
            preparingSeconds = 1,
            finishedSeconds = 1,
        },
        roundDependencies(dependencies)
    )
    local harness = dependencies.TestHarness.new(
        "late-join-lifecycle",
        round,
        clock,
        harnessDependencies(dependencies)
    )

    harness:connect(1)
    harness:connect(2)
    harness:runToState("Playing")
    harness:connect(3, "Late")

    local late = harness:checkpoint("late-join-during-playing")
    harness:expect(
        "late-join-is-not-current-participant",
        late.roundCount == 2
            and late.lateJoinerCount == 1
            and round:getParticipants():isLateJoiner(3)
            and not round:getParticipants():isRoundParticipant(3),
        "late joiner entered the locked current round"
    )

    harness:finish(1)
    harness:advanceToDeadline()
    harness:checkpoint("waiting-between-rounds")

    harness:runToState("Playing")
    local nextRound = harness:checkpoint("late-join-in-next-round")
    harness:expect(
        "late-join-promoted-next-round",
        nextRound.roundCount == 3
            and nextRound.lateJoinerCount == 0
            and round:getParticipants():isRoundParticipant(3),
        "late joiner was not included in the next participant snapshot"
    )

    return harness:report()
end

local function leaveLifecycle(dependencies: Dependencies)
    local clock = dependencies.FakeClock.new()
    local round = dependencies.RoundService.new(
        clock,
        {
            minimumPlayers = 2,
            intermissionSeconds = 1,
            preparingSeconds = 1,
            finishedSeconds = 1,
        },
        roundDependencies(dependencies)
    )
    local harness = dependencies.TestHarness.new(
        "leave-lifecycle",
        round,
        clock,
        harnessDependencies(dependencies)
    )

    harness:connect(1)
    harness:connect(2)
    harness:connect(3)
    harness:runToState("Playing")
    harness:disconnect(3)

    local afterOneLeave = harness:checkpoint("one-participant-leaves")
    harness:expect(
        "round-continues-with-minimum",
        afterOneLeave.state == "Playing" and afterOneLeave.roundCount == 2,
        "round should continue while minimum active participants remain"
    )

    harness:disconnect(2)
    local collapsed = harness:checkpoint("minimum-collapse")
    harness:expect(
        "minimum-collapse-aborts-safely",
        collapsed.state == "Waiting"
            and collapsed.roundLocked == false
            and collapsed.roundCount == 0,
        "active round did not safely abort after dropping below minimum"
    )

    return harness:report()
end

local function repeatedRounds(dependencies: Dependencies, iterations: number)
    local clock = dependencies.FakeClock.new()
    local round = dependencies.RoundService.new(
        clock,
        {
            minimumPlayers = 2,
            intermissionSeconds = 1,
            preparingSeconds = 1,
            finishedSeconds = 1,
        },
        roundDependencies(dependencies)
    )
    local harness = dependencies.TestHarness.new(
        "repeated-rounds-" .. tostring(iterations),
        round,
        clock,
        harnessDependencies(dependencies)
    )

    harness:connect(1)
    harness:connect(2)

    for index = 1, iterations do
        harness:runToState("Playing")
        local playing = harness:checkpoint("playing-" .. tostring(index))

        harness:expect(
            "round-id-" .. tostring(index),
            playing.roundId == index,
            string.format(
                "expected roundId=%d, got %s",
                index,
                tostring(playing.roundId)
            )
        )

        local winner = if index % 2 == 0 then 2 else 1
        harness:finish(winner)
        harness:checkpoint("finished-" .. tostring(index))
        harness:advanceToDeadline()

        local waiting = harness:checkpoint("waiting-" .. tostring(index))
        harness:expect(
            "clean-reset-" .. tostring(index),
            waiting.roundCount == 0
                and waiting.lateJoinerCount == 0
                and waiting.winnerId == nil
                and waiting.roundLocked == false,
            "state leaked across round boundary"
        )
    end

    return harness:report()
end

local function mapVoting(dependencies: Dependencies)
    local vote = dependencies.MapVoteService.new({
        "Foundry",
        "Reactor",
        "Ruins",
    })
    local checkpoints = {}

    local function check(label: string, passed: boolean, message: string?)
        table.insert(checkpoints, {
            label = label,
            snapshot = { state = "MapVote" },
            checks = {
                {
                    name = label,
                    passed = passed,
                    message = if passed then nil else message,
                },
            },
        })
    end

    check(
        "accept-valid-vote",
        vote:vote(1, "Foundry"),
        "valid vote was rejected"
    )
    check(
        "accept-second-vote",
        vote:vote(2, "Reactor"),
        "valid vote was rejected"
    )
    check(
        "replace-own-vote",
        vote:vote(1, "Reactor"),
        "vote replacement failed"
    )

    local counts = vote:getCounts()
    check(
        "replacement-does-not-double-count",
        counts.Foundry == 0 and counts.Reactor == 2 and counts.Ruins == 0,
        "replaced vote was counted twice"
    )

    vote:removePlayer(2)
    counts = vote:getCounts()
    check(
        "leaving-player-vote-removed",
        counts.Reactor == 1,
        "removed player still has a vote"
    )

    vote:vote(2, "Foundry")
    vote:vote(3, "Ruins")
    vote:lock()
    check(
        "locked-vote-rejected",
        not vote:vote(4, "Foundry"),
        "locked vote accepted a new vote"
    )

    local result = vote:resolve(function(tieCount)
        return tieCount
    end)

    check(
        "deterministic-tie-hook",
        result.winner == "Ruins" and #result.tied == 3,
        "tie chooser did not resolve the deterministic tie"
    )

    vote:reset({ "A", "B" })
    check(
        "reset-clears-state",
        not vote:isLocked() and next(vote:getVotes()) == nil,
        "reset left votes or lock state behind"
    )

    return dependencies.Reporter.fromCheckpoints(
        "map-voting",
        checkpoints
    )
end

function RegressionSuite.runAll(dependencyOverrides: Dependencies?)
    local dependencies = resolveDependencies(dependencyOverrides)

    local reports = {
        basicRound(dependencies),
        lateJoinLifecycle(dependencies),
        leaveLifecycle(dependencies),
        repeatedRounds(dependencies, 25),
        mapVoting(dependencies),
    }

    local combined = dependencies.Reporter.combine(
        "roundforge-v0.1-regression",
        reports
    )
    dependencies.Reporter.assertPassed(combined)

    return combined
end

return RegressionSuite
