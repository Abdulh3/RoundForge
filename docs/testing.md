# Deterministic Testing

RoundForge treats testability as part of the architecture rather than an afterthought.

## Why fake time?

Round games often contain long waits:

- intermission
- map voting
- countdown
- round timeout
- winner presentation

Tests should not spend real seconds waiting for these states. `FakeClock` lets a scenario advance authoritative time instantly.

## Basic invariant check

```lua
local RoundForge = require(path.to.RoundForge)

local clock = RoundForge.FakeClock.new()
local rounds = RoundForge.RoundService.new(clock)

local checks = RoundForge.Invariants.runCore(rounds:getSnapshot())
local report = RoundForge.Reporter.fromChecks(checks)

RoundForge.Reporter.assertPassed(report)
```

A report is plain data:

```lua
{
    result = "passed",
    checks = 4,
    failures = 0,
    details = { ... },
}
```

That shape is intentional: a human can inspect it, CI can serialize it, and a coding agent can use it as evidence during a repair loop.

## What to test

A useful game integration should eventually cover at least:

- minimum-player transition
- participant snapshot creation
- late join during an active round
- player leave during every lifecycle state
- winner validation
- full reset to Waiting
- multiple consecutive rounds
- voting reset and player vote removal
- no stale round participants after cleanup

## Repeated lifecycle test

Prefer repeated deterministic cycles to a single happy-path test. Many lifecycle bugs appear only during round two or three because state from the previous round was not cleaned up.

## Future harness

The roadmap includes a scenario harness that will provide:

- seeded randomness
- scripted joins/leaves
- multi-round stress runs
- invariant checks at every transition
- structured failure traces
