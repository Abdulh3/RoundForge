# Agent-friendly workflows

RoundForge is designed so coding agents can work from structured state and reproducible tests instead of guessing from screenshots or unstructured logs.

## Recommended repair loop

1. Reproduce the bug with a deterministic scenario.
2. Capture the round snapshot and invariant report.
3. Change the smallest responsible module.
4. Re-run the exact scenario.
5. Run a repeated lifecycle regression set.
6. Report what was actually tested separately from what still requires real multiplayer testing.

## Useful evidence for agents

Prefer outputs such as:

```lua
{
    scenario = "late-join-during-playing",
    seed = 1337,
    result = "failed",
    state = "Playing",
    roundId = 4,
    failures = {
        {
            invariant = "late-joiner-not-participant",
            playerId = 99,
        },
    },
}
```

over free-form output such as:

```text
something went wrong with player 99
```

## Bound agent changes

An agent should not be told merely to "improve everything." A good maintenance task identifies:

- observed failure
- expected invariant
- reproduction scenario
- files/modules likely involved
- regression scenarios that must still pass

## Human-in-the-loop boundary

Agents can automate code review, deterministic simulation, refactoring, and regression checks. Real Roblox multiplayer behavior can still depend on replication, character physics, network ownership, input, and Studio/runtime behavior. Those claims should be clearly separated from pure harness results.

## Intended future integrations

RoundForge plans to make it straightforward to emit reports suitable for:

- GitHub Actions
- Codex-driven repair workflows
- Studio test harnesses
- local Luau test runners

The framework will not depend on one AI provider or one editor to remain useful.
