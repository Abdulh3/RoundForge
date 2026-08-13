# RoundForge Roadmap

RoundForge is being developed in small, testable milestones. Dates are intentionally not promised until the core API stabilizes.

## v0.1 — Deterministic round core

Goal: prove the lifecycle and QA model with a small usable API.

- [ ] finite-state round service
- [ ] participant snapshot and late-join queue
- [ ] player-leave handling
- [ ] deterministic/injectable clock
- [ ] invariant runner
- [ ] structured JSON-like QA report
- [ ] minimal last-player-standing example
- [ ] lifecycle regression tests

## v0.2 — Voting and arenas

- [ ] map vote service
- [ ] deterministic tie resolution hooks
- [ ] arena registry
- [ ] spawn allocation interface
- [ ] invalid arena filtering
- [ ] anti-repeat map selection helper
- [ ] hot-potato-style lifecycle example

## v0.3 — Roblox integration layer

- [ ] Player adapter for Roblox `Player` instances
- [ ] server snapshot replication helper
- [ ] late-join spectator adapter
- [ ] lifecycle events/signals
- [ ] Studio-friendly installation guide
- [ ] example UI integration

## v0.4 — Agent-friendly QA

- [ ] scenario DSL
- [ ] multi-round stress harness
- [ ] reproducible seeded randomness
- [ ] invariant catalog
- [ ] machine-readable failure artifacts
- [ ] CI example
- [ ] agent workflow guide with bounded repair loops

## v1.0 — Stable core

Criteria before 1.0:

- public API documented
- semantic versioning policy
- reliable repeated-round cleanup
- reference integrations tested
- migration notes for breaking pre-release changes
- real external usage and feedback

## Future ideas

These are deliberately outside the first milestones:

- optional matchmaking adapters
- tournament brackets
- persistent statistics adapters
- richer observability hooks
- plugin ecosystem for game-mode-specific policies

RoundForge should stay focused. Features that belong to a specific game rather than round lifecycle infrastructure should normally remain outside the core.
