# v0.1 API reference

This document describes the public surface of the RoundForge v0.1 source milestone. RoundForge is pre-1.0, so breaking changes may still occur and will be documented in `CHANGELOG.md`.

## `RoundForge.Version`

```lua
RoundForge.Version.string -- "0.1.0"
RoundForge.Version.major  -- 0
RoundForge.Version.minor  -- 1
RoundForge.Version.patch  -- 0
```

## `RoundForge.RoundService`

### `RoundService.new(clock, config?, dependencyOverrides?)`

Creates a round coordinator.

Production integrations normally pass only `clock` and `config`. `dependencyOverrides` exists so standalone Luau tests can execute the same production source without Roblox's `script` hierarchy.

Clock contract:

```lua
{
    now = function(self) -> number
}
```

Recommended Roblox implementation:

```lua
local clock = {
    now = function()
        return workspace:GetServerTimeNow()
    end,
}
```

Config fields:

```lua
{
    minimumPlayers = 2,
    intermissionSeconds = 10,
    preparingSeconds = 3,
    finishedSeconds = 5,
}
```

### `rounds:registerPlayer(participant)`

Registers or refreshes a logical participant.

```lua
rounds:registerPlayer({
    id = player.UserId,
    name = player.Name,
    payload = player,
})
```

`id` must be a number or string and is the identity used across lifecycle snapshots.

### `rounds:unregisterPlayer(id)`

Removes the participant from connected, active-round, and late-join state. During `Preparing` and `Playing`, the framework evaluates the minimum against the **locked active snapshot**, not unrelated late joiners.

### `rounds:start()`

Convenience alias for the first `tick()`. A scheduler still needs to call `tick()` over time.

### `rounds:tick()`

Evaluates player minimums and authoritative deadlines and performs any due lifecycle transition.

RoundForge deliberately does not create its own permanent heartbeat connection. The host game owns scheduling and teardown.

### `rounds:finish(winnerId?)`

Finishes a round from `Playing`. A non-nil winner must belong to the locked participant snapshot.

The game decides *why* somebody won; RoundForge validates and records the lifecycle outcome.

### `rounds:reset()`

Aborts the current lifecycle safely back to `Waiting` and clears round-local membership, winner, and deadline state.

### `rounds:getSnapshot()`

Returns plain inspectable state. Current v0.1 fields include:

```lua
{
    roundId = number,
    state = "Waiting" | "Intermission" | "Preparing" | "Playing" | "Finished",
    deadline = number?,
    remaining = number?,
    minimumPlayers = number,
    connectedCount = number,
    roundCount = number,
    lateJoinerCount = number,
    roundLocked = boolean,
    winnerId = (number | string)?,
    connectedIds = { number | string },
    roundParticipantIds = { number | string },
    lateJoinerIds = { number | string },
    history = { string },
}
```

ID arrays are deterministically sorted to make reports and regression diffs easier to compare.

### `rounds:getParticipants()`

Returns the underlying `ParticipantService` for membership queries.

---

## `RoundForge.ParticipantService`

Usually owned by `RoundService`, but exposed for integrations and testing.

Important methods:

- `connect(participant)`
- `disconnect(id)`
- `lockRound()`
- `unlockRound()`
- `isConnected(id)`
- `isRoundParticipant(id)`
- `isLateJoiner(id)`
- `getParticipant(id)`
- `getConnected()` / `getConnectedIds()`
- `getRoundParticipants()` / `getRoundParticipantIds()`
- `getLateJoiners()` / `getLateJoinerIds()`
- `connectedCount()`
- `roundCount()`
- `lateJoinerCount()`

### Snapshot rule

Calling `lockRound()` copies the current connected set into the active-round set. Players connected afterward are tracked as late joiners and cannot silently enter that active snapshot.

---

## `RoundForge.MapVoteService`

### `MapVoteService.new(options)`

```lua
local vote = RoundForge.MapVoteService.new({
    "Foundry",
    "Reactor",
    "Ruins",
})
```

Options must be unique non-empty strings.

### `vote:vote(participantId, option) -> boolean`

Sets or replaces that participant's single vote. Returns `false` if voting is locked or the option is invalid.

### `vote:removePlayer(participantId)`

Removes a participant's vote, useful for leave handling.

### `vote:lock()` / `vote:isLocked()`

Prevents additional vote mutations.

### `vote:getCounts()`

Returns a count for every configured option, including zero-vote options.

### `vote:resolve(pickIndex?)`

Returns:

```lua
{
    winner = string?,
    counts = { [string] = number },
    tied = { string },
    totalVotes = number,
}
```

If multiple options tie, `pickIndex(tieCount)` can be injected. This makes seeded/random production policies and deterministic tests use the same service.

Without an injected picker, the first tied option wins deterministically.

### `vote:reset(options?)`

Clears votes and lock state and can optionally replace the option set.

---

## `RoundForge.FakeClock`

A monotonic clock for deterministic tests.

```lua
local clock = RoundForge.FakeClock.new(0)
clock:advance(10)
clock:set(25)
print(clock:now()) -- 25
```

Moving backward is rejected.

---

## `RoundForge.TestHarness`

A scenario driver around a real `RoundService` and `FakeClock`.

```lua
local harness = RoundForge.TestHarness.new(
    "late-join-case",
    rounds,
    clock,
    nil,
    12345 -- optional reproducibility metadata
)
```

Important methods:

- `connect(id, name?)`
- `disconnect(id)`
- `tick()`
- `advance(seconds)`
- `advanceToDeadline()`
- `runToState(state, maxTransitions?)`
- `finish(winnerId?)`
- `checkpoint(label)`
- `expect(label, passed, message?)`
- `report()`

Normal checkpoints run the core invariant catalog automatically.

---

## `RoundForge.Invariants`

`Invariants.runCore(snapshot)` returns check records for the v0.1 guarantees, including state validity, lock/state consistency, winner validity, set/count consistency, late-join disjointness, waiting-state cleanup, and active minimums.

Integrations can add game-specific invariants beside the core catalog.

---

## `RoundForge.Reporter`

### `Reporter.fromCheckpoints(scenario, checkpoints, seed?)`

Produces a plain-data report with:

- scenario name
- pass/fail result
- number of checks/failures/checkpoints
- optional seed metadata
- per-check failure context
- checkpoint trace containing snapshots

### `Reporter.combine(name, reports)`

Combines multiple scenario reports into a suite result.

### `Reporter.assertPassed(report)`

Throws a concise failure summary when a report is not green.

---

## `RoundForge.RegressionSuite`

`RegressionSuite.runAll()` executes the repository's deterministic v0.1 lifecycle scenarios. Standalone tests use dependency injection; Roblox integrations can require it through the package normally.

For repository development, run the suite through `tests/run.luau` with Lune rather than calling it manually.
