# Contributing to RoundForge

Thanks for helping improve RoundForge.

RoundForge is pre-1.0, so small, well-scoped contributions are preferred over broad rewrites. The goal is a reliable lifecycle core, not a collection of unrelated Roblox utilities.

## Before opening a pull request

1. Check existing issues and pull requests.
2. For large API or architecture changes, open an issue first.
3. Keep game-specific mechanics outside the framework core unless they demonstrate a reusable lifecycle requirement.
4. Add or update deterministic regression coverage for behavior changes.
5. Update docs and `CHANGELOG.md` when public behavior changes.

## Local validation

RoundForge's deterministic core is tested with Lune.

```bash
lune run tests/run
```

The same regression runner is executed by GitHub Actions on `main` and pull requests.

If your change only affects Roblox-specific integration that cannot be reproduced under Lune, explain the Studio/server test you performed in the pull request instead of pretending the deterministic suite covers it.

## Design expectations

Contributions should preserve these principles:

- server-authoritative state
- explicit lifecycle transitions
- deterministic and injectable time
- safe cleanup after rounds
- late-join and player-leave robustness
- structured, machine-readable QA output
- game-specific behavior stays outside the core when possible
- no hidden production dependencies

## Regression expectations

A lifecycle change should normally include a scenario that demonstrates both the intended behavior and its cleanup boundary.

Good regression cases include:

- a specific join/leave ordering
- a transition deadline race
- a stale participant/winner reference
- voting state leaking into another round
- behavior that only fails on the second or later round

When a bug can be expressed through `TestHarness`, prefer that over a long real-time integration test.

## Pull request checklist

The repository PR template contains the canonical checklist. At minimum:

- [ ] Change is focused and documented
- [ ] Deterministic tests cover the changed lifecycle behavior when applicable
- [ ] No real-time sleeps are required by deterministic core tests
- [ ] Temporary state and connections have a cleanup path
- [ ] Public APIs and docs are updated if needed
- [ ] Breaking pre-1.0 behavior is recorded in the changelog

## AI-assisted contributions

AI-assisted changes are welcome. Please review generated code, run relevant tests, and mention material agent assistance in the PR when useful for understanding the change.

A coding agent passing CI is evidence, not authorship or final approval. Human maintainers remain responsible for deciding whether a change preserves RoundForge's invariants and scope.

## Commit style

Conventional-style prefixes are encouraged:

- `feat:` new functionality
- `fix:` bug fix
- `test:` test coverage
- `docs:` documentation
- `refactor:` internal restructuring
- `chore:` maintenance

## Reporting bugs

Use the bug-report issue template when possible. A strong report contains:

- expected behavior
- actual behavior
- minimal lifecycle reproduction
- Roblox/Luau environment details
- relevant RoundForge version or commit
- structured harness output when available

Security-sensitive reports should follow `SECURITY.md` instead of a public issue.

## Maintainers

See [`MAINTAINERS.md`](MAINTAINERS.md) for current maintainer responsibilities.

## Code of conduct

Participation in this project is governed by [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
