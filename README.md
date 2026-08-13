# RoundForge

**Server-authoritative round framework and deterministic QA toolkit for Roblox/Luau.**

> Status: early development / pre-release. RoundForge is being built in public and is not yet recommended for production games.

RoundForge is an open-source toolkit for building multiplayer round-based Roblox experiences without rewriting the same lifecycle code for every game. It focuses on the parts that are easy to get subtly wrong: participant snapshots, late joins, leaves, map voting, state transitions, deterministic timers, cleanup, and repeatable QA.

The project is also designed to be **agent-friendly**. Its state model and test reports are intentionally structured so human maintainers, CI systems, and coding agents can inspect the same facts instead of relying on ad-hoc console output.

## Goals

- Server-authoritative round lifecycle
- Explicit, validated match state transitions
- Snapshot-based participant handling
- Late-join and leave safety
- Deterministic map voting and tie breaking
- Arena/spawn adapters without forcing one map layout
- Deterministic clocks for fast tests
- Invariant checks for deadlocks, stale participants, invalid winners, and cleanup leaks
- Machine-readable QA reports for CI and AI-assisted maintenance
- Small composable modules instead of a single framework megascript

## Non-goals

RoundForge is not a full game template, monetization system, UI framework, datastore wrapper, combat framework, or anti-cheat product. It should make the lifecycle of round-based games reliable while leaving game-specific mechanics to the developer.

## Example

```lua
local RoundForge = require(path.to.RoundForge)

local clock = RoundForge.FakeClock.new()
local round = RoundForge.RoundService.new({
    clock = clock,
    minimumPlayers = 2,
    intermissionSeconds = 10,
})

round:registerPlayer({ id = 101, name = "A" })
round:registerPlayer({ id = 102, name = "B" })

round:start()
clock:advance(10)

local snapshot = round:getSnapshot()
print(snapshot.state)
```

The public API is still evolving. See [`ROADMAP.md`](ROADMAP.md) for the path to the first stable release.

## Project structure

```text
src/
  shared/       reusable primitives and types
  server/       round, participant, voting, arena and replication services
  testing/      fake clock, invariants, harness and structured reporter
examples/       small reference integrations
docs/           architecture and guides
```

## Design principles

1. **The server owns truth.** Clients can request actions, not decide match outcomes.
2. **Time is injectable.** Core logic should not depend on real wall-clock waiting in tests.
3. **State is inspectable.** Important decisions should be representable as snapshots and events.
4. **Cleanup is part of correctness.** A round is not finished until temporary state is gone.
5. **Game-specific mechanics stay outside the core.** RoundForge coordinates the lifecycle; your game defines what happens during `Playing`.
6. **Agents get structured evidence.** Test output should make failures easy to locate and reproduce.

## Planned first milestone

The first milestone focuses on a usable vertical slice:

- finite-state round loop
- participant snapshot and late-join queue
- leave handling
- map vote service
- fake clock
- invariant runner
- structured test report
- two reference modes: last-player-standing and hot-potato-style lifecycle

## Contributing

Contributions are welcome while the API is taking shape. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request. Bug reports and design discussions are especially useful during the pre-release phase.

## Security

Please do not disclose security-sensitive issues publicly before reading [`SECURITY.md`](SECURITY.md).

## License

RoundForge is licensed under the [MIT License](LICENSE).
