# Deterministic testing

RoundForge treats testability as part of the architecture rather than an afterthought.

The v0.1 core has two clocks in mind:

- a production clock supplied by the Roblox game, normally backed by `workspace:GetServerTimeNow()`
- `FakeClock`, which can move authoritative time forward instantly in tests

That means a 10-second intermission does not require a 10-second test.

## Run the repository regression suite

RoundForge's repository tests use [Lune](https://github.com/lune-org/lune), a standalone Luau runtime.

From the repository root:

```bash
lune run tests/run
```

CI runs the same command on every push to `main` and on pull requests.

## What the v0.1 regression suite covers

`RegressionSuite.runAll()` currently exercises:

- a complete Waiting → Intermission → Preparing → Playing → Finished → Waiting cycle
- locked participant snapshots
- winner validation
- late join during `Playing`
- promotion of a late joiner into the next round
- player leave while enough active participants remain
- minimum-player collapse while a round is active
- 25 consecutive deterministic rounds
- cleanup after every repeated round
- map vote replacement
- vote removal when a player leaves
- vote locking
- deterministic tie-resolution injection
- vote reset

## TestHarness

`TestHarness` is intentionally small. It drives the real `RoundService` instead of creating a second test-only implementation.

```lua
local clock = RoundForge.FakeClock.new()
local rounds = RoundForge.RoundService.new(clock, {
    minimumPlayers = 2,
    intermissionSeconds = 10,
})

local harness = RoundForge.TestHarness.new("my-scenario", rounds, clock)

harness:connect(1, "Alpha")
harness:connect(2, "Bravo")
harness:runToState("Playing")
harness:checkpoint("playing")

rounds:finish(1)
harness:checkpoint("finished")
harness:advanceToDeadline()
harness:checkpoint("waiting-again")

RoundForge.Reporter.assertPassed(harness:report())
```

## Core invariants

Each normal checkpoint runs a set of lifecycle invariants, including:

- the state name is valid
- the participant snapshot is locked only in the correct states
- a winner exists only in `Finished`
- a winner belongs to the locked participant snapshot
- connected/round/late-join counts match their ID snapshots
- late joiners are disjoint from active round participants
- `Waiting` contains no stale round state
- active rounds satisfy the configured participant minimum

## Agent-friendly reports

Reports are plain Luau tables rather than formatted-only console strings. A report contains the scenario name, pass/fail result, check count, failure count, checkpoint count, and per-check details.

That structure is deliberate: a human maintainer can inspect it, CI can fail on it, and a coding agent can use the same evidence when diagnosing a lifecycle regression.

## Roblox Studio integration tests

The deterministic suite validates the framework core. A real game should still test Roblox-specific integration in Studio, especially:

- actual `PlayerAdded` / `PlayerRemoving` timing
- character respawns
- teleport/spawn behavior
- RemoteEvent contracts
- collision and physics behavior
- client UI projections

RoundForge keeps those concerns outside the deterministic core so they can be tested at the correct integration layer.
