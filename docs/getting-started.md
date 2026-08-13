# Getting Started

RoundForge is currently pre-release. The API may change before v1.0.

## Installation

For now, copy the `src` directory into your Roblox/Luau project so that the folder represented by `src/init.luau` becomes the package root.

A package manager/distribution workflow may be added after the first API milestone stabilizes.

## Minimal lifecycle example

```lua
local RoundForge = require(path.to.RoundForge)

local clock = {
    now = function()
        return workspace:GetServerTimeNow()
    end,
}

local rounds = RoundForge.RoundService.new(clock, {
    minimumPlayers = 2,
    intermissionSeconds = 10,
    preparingSeconds = 3,
    finishedSeconds = 5,
})

rounds:registerPlayer({ id = 1001, name = "PlayerA" })
rounds:registerPlayer({ id = 1002, name = "PlayerB" })

-- Call from your own server loop/scheduler.
rounds:tick()

print(rounds:getSnapshot().state)
```

## Important integration rule

`RoundService` coordinates the round lifecycle. It does not decide how your game eliminates players, awards points, moves characters, or handles game-specific objectives.

Your game-specific system should finish the round when its own win condition is satisfied:

```lua
rounds:finish(winnerUserId)
```

## Testing without waiting

```lua
local clock = RoundForge.FakeClock.new()
local rounds = RoundForge.RoundService.new(clock, {
    minimumPlayers = 2,
    intermissionSeconds = 10,
    preparingSeconds = 3,
})

rounds:registerPlayer({ id = 1 })
rounds:registerPlayer({ id = 2 })

rounds:tick() -- enters Intermission
clock:advance(10)
rounds:tick() -- enters Preparing
clock:advance(3)
rounds:tick() -- enters Playing
```

No real 13-second wait is required.

## Next

- Read [`architecture.md`](architecture.md) for design boundaries.
- Read [`testing.md`](testing.md) for invariant-based QA.
- Check `examples/` for small reference scenarios.
