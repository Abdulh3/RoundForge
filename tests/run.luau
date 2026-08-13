local StateMachine = require("../src/shared/StateMachine")
local ParticipantService = require("../src/server/ParticipantService")
local MapVoteService = require("../src/server/MapVoteService")
local RoundService = require("../src/server/RoundService")
local FakeClock = require("../src/testing/FakeClock")
local Invariants = require("../src/testing/Invariants")
local Reporter = require("../src/testing/Reporter")
local TestHarness = require("../src/testing/TestHarness")
local RegressionSuite = require("../src/testing/RegressionSuite")

local report = RegressionSuite.runAll({
    FakeClock = FakeClock,
    Reporter = Reporter,
    TestHarness = TestHarness,
    RoundService = RoundService,
    MapVoteService = MapVoteService,
    StateMachine = StateMachine,
    ParticipantService = ParticipantService,
    Invariants = Invariants,
})

print(string.format(
    "RoundForge v0.1 regression: %s | %d checks | %d checkpoints | %d failures",
    report.result,
    report.checks,
    report.checkpoints,
    report.failures
))

for _, scenario in report.reports do
    print(string.format(
        "  %-28s %s (%d checks, %d failures)",
        scenario.scenario,
        scenario.result,
        scenario.checks,
        scenario.failures
    ))
end
