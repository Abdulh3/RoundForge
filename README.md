# RoundForge

[![CI](https://github.com/Abdulh3/RoundForge/actions/workflows/ci.yml/badge.svg)](https://github.com/Abdulh3/RoundForge/actions/workflows/ci.yml)
![Luau](https://img.shields.io/badge/language-Luau-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/source-v0.1.0-orange)

**Server-authoritative round framework and deterministic QA toolkit for Roblox/Luau.**

RoundForge is an open-source toolkit for multiplayer Roblox experiences that run in repeated rounds: survival, tag, hot potato, minigames, social-deduction-style lobbies, last-player-standing modes, and similar games.

It focuses on the lifecycle code that is simple to sketch but easy to get subtly wrong in production: participant snapshots, late joins, leaves, authoritative deadlines, state transitions, winners, cleanup, map voting, and repeatable regression testing.

RoundForge is also intentionally **agent-friendly**. Important state is exposed as structured snapshots, tests use deterministic time, and QA results are plain data that a human, CI job, or coding agent can inspect.

> **Project status:** v0.1.0 source milestone. The deterministic core is usable for experimentation and integration work, but the public API is still pre-1.0 and may evolve.

## Why RoundForge?

A typical round game eventually needs to answer questions like:

- Who exactly belongs to this round?
- What happens if somebody joins after the round has started?
- Can a late joiner accidentally keep a dying round alive?
- What happens if the current winner or participant leaves?
- Did the previous round actually clean itself up?
- Can voting state leak into the next match?
- Can tests advance a 30-second timer without really waiting 30 seconds?

RoundForge makes those questions explicit instead of hiding them inside one large game script.

## v0.1 features

- explicit finite-state round lifecycle
- server-owned participant registry
- locked participant snapshots at round start
- late-join queue that cannot enter the active snapshot
- leave handling based on active participants, not unrelated connected players
- authoritative injectable clock
- deterministic `FakeClock`
- winner validation
- map voting with one vote per participant
- vote replacement and removal
- lockable voting and deterministic tie-resolution hook
- lifecycle invariants
- structured scenario reports with checkpoint traces and optional seed metadata
- reusable deterministic `TestHarness`
- regression suite including 25 consecutive round cycles and join/leave edge cases
- standalone Luau test runner with Lune
- GitHub Actions CI
- runnable Roblox last-player-standing integration example

## Lifecycle

```text
Waiting
   ↓ enough connected players
Intermission
   ↓ deadline
Preparing  ← participant snapshot locks here
   ↓ deadline
Playing
   ↓ game-specific finish condition
Finished
   ↓ presentation deadline
Waiting    ← round state is fully cleaned here
```

A player who joins after the snapshot locks remains connected but is classified as a late joiner until the next round.

## Quick example

```lua
local RoundForge = require(ServerScriptService.RoundForge)

local clock = {
    now = function()
        return workspace:GetServerTimeNow()
    end,
}

local rounds = RoundForge.RoundService.new(clock, {
    minimumPlayers = 2,
    intermissionSeconds = 10,
    preparingSeconds = 3,
    finishedSeconds = 5,
})

rounds:registerPlayer({ id = 101, name = "Alpha" })
rounds:registerPlayer({ id = 102, name = "Bravo" })

rounds:tick() -- Waiting -> Intermission
```

Your game owns the scheduler and game-specific rules. RoundForge owns lifecycle truth.

See [`examples/last-player-standing`](examples/last-player-standing) for a complete Roblox-side example.

## Documentation

- [Getting started](docs/getting-started.md)
- [v0.1 API reference](docs/api-reference.md)
- [Architecture](docs/architecture.md)
- [Deterministic testing](docs/testing.md)
- [Agent workflows](docs/agent-workflows.md)
- [Roadmap](ROADMAP.md)
- [Maintainers](MAINTAINERS.md)
- [Contributing](CONTRIBUTING.md)

## Deterministic testing

The repository regression suite runs the real core modules with an injected fake clock.

```bash
lune run tests/run
```

The suite covers the normal lifecycle, late joins, leaves during multiple lifecycle states, minimum-player collapse, a late-join race, winner-leave cleanup, map voting, and 25 repeated rounds without real-time waits.

A typical scenario can also be authored directly:

```lua
local clock = RoundForge.FakeClock.new()
local rounds = RoundForge.RoundService.new(clock)
local harness = RoundForge.TestHarness.new("late-join", rounds, clock)

harness:connect(1)
harness:connect(2)
harness:runToState("Playing")
harness:connect(3)
harness:checkpoint("player-3-is-late")

RoundForge.Reporter.assertPassed(harness:report())
```

Read [`docs/testing.md`](docs/testing.md) for the invariant model and CI workflow.

## Project structure

```text
src/
  init.luau
  shared/
    StateMachine.luau
    Version.luau
  server/
    ParticipantService.luau
    RoundService.luau
    MapVoteService.luau
  testing/
    FakeClock.luau
    Invariants.luau
    Reporter.luau
    TestHarness.luau
    RegressionSuite.luau

tests/
  run.luau

examples/
  last-player-standing/

docs/
  api-reference.md
  architecture.md
  getting-started.md
  testing.md
  agent-workflows.md
```

## Design principles

1. **The server owns truth.** Clients may request actions, but participant membership, deadlines, states, and winners are authoritative.
2. **Time is injectable.** Core tests should not depend on `task.wait()` or real wall-clock delays.
3. **Round membership is a snapshot.** Connected players and current participants are different concepts.
4. **Cleanup is correctness.** `Finished` is not the end of the lifecycle; stale state must be removed before the next round.
5. **Game mechanics stay outside the core.** RoundForge coordinates *when* a round plays and *who* is in it. Your game decides how somebody wins or loses.
6. **State should be inspectable.** Snapshots and reports are intentionally easy to reason about and serialize.
7. **Automation should test the same source used in production.** Standalone tests inject dependencies instead of maintaining a second round implementation.

## What RoundForge is not

RoundForge is not a combat framework, UI framework, datastore wrapper, anti-cheat system, monetization package, or complete game template.

Those systems can integrate with RoundForge without becoming part of the round lifecycle core.

## Roadmap

The next milestones focus on:

- arena registry and spawn allocation
- reusable map-selection pipeline
- Roblox `Player` adapter
- versioned snapshot replication
- stronger property/stress scenarios
- package/release automation

See [`ROADMAP.md`](ROADMAP.md).

## Contributing

Contributions, bug reports, test cases, and API-design feedback are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request.

The most useful early contributions are small reproducible lifecycle scenarios: a join/leave ordering, reset bug, voting edge case, or invariant that RoundForge should guarantee.

## Security

For security-sensitive reports, read [`SECURITY.md`](SECURITY.md) before opening a public issue.

## License

RoundForge is available under the [MIT License](LICENSE).
