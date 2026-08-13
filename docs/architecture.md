# Architecture

RoundForge separates **round lifecycle infrastructure** from **game-specific mechanics**.

## Core flow

```text
Waiting
  -> Intermission
  -> Preparing
  -> Playing
  -> Finished
  -> Waiting
```

Transitions are explicit. Invalid transitions fail loudly instead of silently mutating state.

`Preparing` is the boundary where the current connected set becomes a locked participant snapshot. `Finished` is a presentation state, not the cleanup boundary; round-local state is cleared on the transition back to `Waiting`.

## Participant snapshots

A central rule is that the player list for an active round is a snapshot, not a live alias of everyone currently connected.

```text
connected players
  -> Preparing / lockRound()
  -> round participant snapshot

new player joins while locked
  -> late joiner
  -> waits for next round
```

This prevents a class of bugs where a player joins halfway through a match and accidentally changes current-round membership, win conditions, or active-player minimums.

When the round is locked, minimum-player checks use the **active round snapshot**, not total connected-player count. A late joiner therefore cannot accidentally keep a collapsed active round alive.

## Server authority

RoundForge assumes authoritative decisions live on the server. Client-facing adapters may submit requests, but clients should not decide:

- round state
- participant membership
- voting winner
- authoritative deadlines
- winner
- game-specific eliminations

RoundForge v0.1 contains the deterministic server-side core. A versioned Roblox replication adapter is planned as a later layer rather than being mixed into the lifecycle service.

## Injectable time

Core services depend on a small clock interface rather than calling `task.wait()` internally.

Production Roblox code can supply a clock backed by `workspace:GetServerTimeNow()`. Tests can supply `FakeClock` and advance time instantly.

```text
RoundService
    |
    +-- production clock -> Roblox server time
    |
    +-- test clock ------> FakeClock
```

This lets the repository simulate many round cycles without waiting through real intermissions or result screens.

## Testing architecture

The v0.1 testing layer has four responsibilities:

1. **Drive scenarios** through `TestHarness` with deterministic time and participant actions.
2. **Check invariants** against every important lifecycle snapshot.
3. **Preserve evidence** through checkpoint traces and optional seed metadata.
4. **Aggregate results** through `Reporter` so local runs, CI, humans, and coding agents can reason from the same data.

```text
RegressionSuite
      |
      v
 TestHarness ---> RoundService ---> ParticipantService
      |                |
      |                +---------> StateMachine
      |
      +--> FakeClock
      +--> Invariants
      +--> Reporter
```

`tests/run.luau` injects the standalone dependencies into the same source modules used by Roblox. RoundForge does not maintain a second test-only implementation of round behavior.

## Voting boundary

`MapVoteService` stores one vote per participant and owns replacement, removal, locking, counting, and tie resolution. It does not know what a Roblox map model or spawn point is.

That separation is intentional. The planned arena layer can validate actual arenas and capacities while the vote primitive remains deterministic and independently testable.

## Scheduler ownership

`RoundService` does not create a permanent `Heartbeat` or background thread. The host game decides how often to call `tick()`.

This makes ownership and teardown explicit and keeps deterministic tests free from hidden schedulers.

## Game-specific boundary

RoundForge deliberately does not own your game's combat, bomb, role, scoring, movement, UI, or economy mechanics. A game mode should observe lifecycle state and implement its own domain rules.

For example, a hot-potato game can use RoundForge to manage participants, voting, late joins, deadlines, and round cleanup while keeping bomb passing and explosion rules in a separate game-specific service.

Likewise, the included last-player-standing example uses `Humanoid.Died` as its elimination signal without teaching the framework core what a Humanoid is.

## Planned integration layers

The roadmap intentionally adds Roblox-specific features after the deterministic core:

- arena registry and spawn allocation
- Roblox `Player` adapter
- server-to-client snapshot projection
- late-join spectator projection
- lifecycle signals/events

These adapters should depend on the core rather than forcing Roblox object lifetimes into it.
