## What changed?

Describe the lifecycle, testing, documentation, or integration change.

## Why?

Link the issue or explain the concrete problem this solves.

## Validation

- [ ] I ran `lune run tests/run` locally, or CI provides equivalent evidence.
- [ ] Lifecycle semantic changes include or update a deterministic regression scenario.
- [ ] No game-specific behavior was added to the framework core without a reusable reason.
- [ ] Public API/documentation was updated when behavior changed.
- [ ] Breaking pre-1.0 changes are recorded in `CHANGELOG.md`.
- [ ] Temporary state/connections created by this change have a cleanup path.

## Agent-assisted changes

If Codex or another coding agent materially contributed, briefly note what was generated or reviewed and what evidence you used to validate it. Maintainers remain responsible for the final change.
