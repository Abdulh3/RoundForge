# RoundForge Roadmap

RoundForge is developed in small, testable milestones. Dates are intentionally not promised until the API has real external usage.

## v0.1 — Deterministic round core ✅

Goal: prove the lifecycle and QA model with a small usable API.

- [x] finite-state round service
- [x] participant snapshot and late-join queue
- [x] player-leave handling
- [x] deterministic/injectable clock
- [x] invariant runner
- [x] structured machine-readable QA report
- [x] reusable deterministic `TestHarness`
- [x] runnable last-player-standing example
- [x] lifecycle regression suite
- [x] 25-round cleanup regression scenario
- [x] standalone Lune runner
- [x] GitHub Actions CI

## v0.2 — Voting and arenas

Voting primitives landed early in v0.1 because they are useful for lifecycle regression coverage.

- [x] map vote service
- [x] deterministic tie-resolution hook
- [x] vote replacement/removal/reset coverage
- [ ] arena registry
- [ ] spawn allocation interface
- [ ] invalid arena filtering
- [ ] anti-repeat map selection helper
- [ ] hot-potato-style lifecycle example

Tracking: issue #3.

## v0.3 — Roblox integration layer

- [ ] `Player` adapter for Roblox `Player` instances
- [ ] server snapshot replication helper
- [ ] late-join spectator adapter
- [ ] lifecycle events/signals
- [ ] Studio-friendly installation guide
- [ ] example UI integration

Tracking: issue #4.

## v0.4 — Agent-friendly QA expansion

The first deterministic/agent-readable QA layer shipped in v0.1. This milestone expands it rather than starting it from scratch.

- [ ] scenario DSL
- [ ] reproducible seeded randomness helper
- [ ] property/stress scenarios beyond fixed cases
- [ ] machine-readable failure artifact export
- [ ] CI artifact example
- [ ] bounded agent repair-loop example

## v1.0 — Stable core

Criteria before 1.0:

- public API fully documented
- semantic versioning policy finalized
- reliable repeated-round cleanup
- reference integrations tested in real Roblox projects
- migration notes for breaking pre-release changes
- real external usage and maintainer feedback

## Future ideas

These are deliberately outside the first milestones:

- optional matchmaking adapters
- tournament brackets
- persistent statistics adapters
- richer observability hooks
- plugin ecosystem for game-mode-specific policies

RoundForge should stay focused. Features that belong to a specific game rather than round lifecycle infrastructure should normally remain outside the core.
