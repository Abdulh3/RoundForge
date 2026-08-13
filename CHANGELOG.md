# Changelog

All notable changes to RoundForge are documented here.

RoundForge uses semantic versioning for source milestones. The API remains pre-1.0 and may change as real integrations provide feedback.

## [0.1.0] - 2026-08-13

### Added

- explicit `Waiting → Intermission → Preparing → Playing → Finished` state machine
- server-owned participant registry
- locked participant snapshots
- late-join tracking that excludes new players from an active round
- deterministic participant ID snapshots
- active-participant minimum handling for leave/collapse cases
- injectable authoritative clock
- deterministic `FakeClock`
- winner validation against the active round snapshot
- map voting with vote replacement, player removal, locking, reset, and deterministic tie hooks
- nine core lifecycle invariants
- structured QA reporter with checkpoint traces and optional seed metadata
- reusable deterministic `TestHarness`
- regression scenarios for normal rounds, late joins, leaves across lifecycle states, winner leave, and voting
- 25-round repeated lifecycle regression scenario
- standalone Lune test runner
- GitHub Actions CI for deterministic regression testing
- runnable Roblox last-player-standing integration example
- `Version` module and `VERSION` source marker
- project documentation, contribution guide, security policy, code of conduct, roadmap, maintainer record, issue templates, PR checklist, and agent-workflow notes

### Verified QA

- GitHub Actions deterministic regression: **920 checks, 168 checkpoints, 0 failures**
- scenarios include basic lifecycle, late-join promotion, Intermission/Preparing/Playing leave handling, late-join active-minimum race, winner-leave cleanup, 25 repeated rounds, and map voting

### Fixed

- late joiners can no longer keep an active round alive after the locked participants drop below the configured minimum
- repeated vote changes no longer risk stale vote accounting
- waiting-state cleanup is now checked as an explicit invariant

## Unreleased

### Planned

- arena registry and spawn allocation
- reusable map-selection pipeline
- Roblox `Player` adapter
- versioned state replication
- expanded integration and property/stress testing
