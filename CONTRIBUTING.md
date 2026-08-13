# Contributing to RoundForge

Thanks for helping improve RoundForge.

RoundForge is in early development, so small, well-scoped contributions are preferred over broad rewrites.

## Before opening a pull request

1. Check existing issues and pull requests.
2. For large API or architecture changes, open an issue first.
3. Keep game-specific mechanics outside the framework core unless they demonstrate a reusable lifecycle requirement.
4. Add or update deterministic tests for behavior changes.
5. Update docs when public behavior changes.

## Design expectations

Contributions should preserve these principles:

- server-authoritative state
- explicit lifecycle transitions
- deterministic and injectable time
- safe cleanup after rounds
- late-join and player-leave robustness
- structured, machine-readable QA output
- no invented external asset IDs or hidden production dependencies

## Pull request checklist

- [ ] Change is focused and documented
- [ ] Tests cover normal behavior and at least one edge case
- [ ] No real-time sleeps are required by deterministic unit tests
- [ ] Temporary state is cleaned up
- [ ] Public APIs have clear names and comments
- [ ] README/docs are updated if needed

## Commit style

Conventional-style prefixes are encouraged:

- `feat:` new functionality
- `fix:` bug fix
- `test:` test coverage
- `docs:` documentation
- `refactor:` internal restructuring
- `chore:` maintenance

## Reporting bugs

Please include:

- expected behavior
- actual behavior
- minimal reproduction
- Roblox/Luau environment details
- relevant RoundForge version or commit
- structured harness output when available

## Code of conduct

Participation in this project is governed by `CODE_OF_CONDUCT.md`.
