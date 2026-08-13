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

## Participant snapshots

A central rule is that the player list for an active round is a snapshot, not a live alias of everyone currently connected.

```text
Lobby players
  -> lockRound()
  -> round participant snapshot

new player joins while locked
  -> late joiner
  -> waits for next round
```

This prevents a common class of bugs where a player joins halfway through a match and accidentally changes win conditions, spawn counts, or elimination logic.

## Server authority

RoundForge assumes authoritative decisions live on the server. Client-facing adapters may submit requests, but clients should not decide:

- round state
- participant membership
- voting winner
- authoritative deadlines
- winner
- eliminations

## Injectable time

Core services should depend on a small clock interface rather than calling `task.wait()` internally.

Production code can supply a real clock. Tests can supply `FakeClock` and advance time instantly.

This makes tests fast and reproducible.

## Testing architecture

The testing layer has three responsibilities:

1. **Drive scenarios** with deterministic time and inputs.
2. **Check invariants** such as valid state, correct lock state, and winner validity.
3. **Report structured evidence** that can be read by humans, CI, or coding agents.

A future scenario harness will support repeated match simulations and seeded random choices.

## Boundaries

RoundForge deliberately does not own your game's combat, bomb, role, scoring, or movement mechanics. A game mode should observe lifecycle events/state and implement its own domain rules.

For example, a hot-potato game can use RoundForge to manage participants, voting, late joins, and round cleanup while keeping bomb passing in a separate game-specific service.
