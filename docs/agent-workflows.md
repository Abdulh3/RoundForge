# Agent-friendly workflows

RoundForge is designed so coding agents can work from structured state and reproducible tests instead of guessing from screenshots or unstructured logs.

The goal is not autonomous merging. The goal is to give an agent enough deterministic evidence to propose a bounded change that a maintainer can review.

## Recommended repair loop

1. Reproduce the bug with a deterministic `TestHarness` scenario when possible.
2. Capture checkpoints and the structured invariant report.
3. Identify the smallest lifecycle boundary that violates the expected invariant.
4. Change the smallest responsible module.
5. Re-run the exact reproduction.
6. Run the full regression suite.
7. Summarize the changed behavior and evidence for maintainer review.
8. Keep Roblox-specific claims separate from standalone harness claims.

## Actual v0.1 report shape

A scenario report is plain Luau data. A simplified result looks like:

```lua
{
    scenario = "late-join-case",
    seed = 1337,
    result = "failed",
    checks = 27,
    failures = 1,
    checkpoints = 3,
    details = {
        {
            name = "late-joiners-disjoint-from-round",
            passed = false,
            checkpoint = "player-3-connected",
            state = "Playing",
            message = "participant appears in both round and late-join sets: 3",
        },
    },
    trace = {
        {
            label = "player-3-connected",
            at = 14,
            snapshot = {
                state = "Playing",
                roundId = 4,
                -- additional inspectable state omitted here
            },
        },
    },
}
```

This is preferable to a single console line such as:

```text
something went wrong with player 3
```

The structured result tells a maintainer or agent which invariant failed, at which checkpoint, in which lifecycle state, and preserves the associated state trace.

## Turning an issue into a bounded agent task

A strong maintenance task contains:

- observed behavior
- expected invariant
- minimal reproduction sequence
- RoundForge version/commit
- relevant report/checkpoint
- explicit non-goals
- regression scenarios that must still pass

For example:

```text
Reproduce issue #42 as a TestHarness scenario.
Expected: a player joining after Preparing starts must not enter roundParticipantIds.
Fix only the participant/lifecycle boundary responsible for the failure.
Run the exact reproduction and then lune run tests/run.
Do not change voting or public API unless the regression proves it is necessary.
Return the failing-before/passing-after evidence for review.
```

## Pull-request review workflow

An agent can assist a maintainer by:

1. reading the changed files and linked issue
2. identifying which server-authoritative invariants are affected
3. checking whether a deterministic regression exists
4. running or interpreting CI
5. flagging undocumented public API changes
6. producing review notes tied to concrete behavior rather than style alone

A green CI result is useful evidence, but it does not replace maintainer review.

## Triage workflow

For a new lifecycle bug report, an agent can help classify it into one of these buckets:

- deterministic core bug — should become a Lune/TestHarness reproduction
- Roblox integration bug — requires Studio/server evidence
- game-specific behavior — likely belongs outside RoundForge core
- documentation/API ambiguity — may need docs rather than code
- security-sensitive server-authority issue — follow `SECURITY.md`

This keeps the framework focused and prevents every Roblox game bug from becoming framework scope.

## Release workflow

Before a source milestone or release, an agent can help a maintainer verify:

- full deterministic regression suite is green
- changelog matches actual shipped behavior
- version markers agree
- public API reference matches implementation
- roadmap completion claims are supported
- known Roblox integration limitations are documented
- no open release-blocking issue was silently ignored

## Human-in-the-loop boundary

Agents can automate code review, deterministic simulation, refactoring, documentation checks, and regression analysis. Real Roblox multiplayer behavior can still depend on replication, character physics, network ownership, input, character respawns, and Studio/runtime behavior.

RoundForge therefore separates two kinds of evidence:

**Deterministic core evidence**
: Produced by `FakeClock`, `TestHarness`, invariants, and CI.

**Roblox integration evidence**
: Produced by actual Studio/server/client tests for Roblox-specific APIs and physics.

Agents and maintainers should never present one as proof of the other.

## Provider-neutral by design

RoundForge's reports are plain data and its tests are ordinary Luau. The framework does not require Codex, ChatGPT, or any other AI provider in production.

That is intentional: agent tooling should improve the maintenance workflow without becoming a runtime dependency of games using RoundForge.
