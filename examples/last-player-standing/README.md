# Last Player Standing example

This is the smallest complete Roblox-side example for RoundForge v0.1.

It demonstrates:

- connecting current and future Roblox players to `ParticipantService`
- Waiting → Intermission → Preparing → Playing → Finished → Waiting
- a locked participant snapshot
- late joins staying outside the active round
- removing a leaving player from the active snapshot
- game-specific elimination outside the RoundForge core
- selecting the last remaining participant as the winner
- starting a second round without stale state

## Studio setup

1. Put the RoundForge package in `ServerScriptService` and name the package root `RoundForge`.
2. Create a normal Script beside it.
3. Copy `server-example.luau` into that Script.
4. Start a Studio server with at least two players.
5. Kill one participating character during `Playing` to finish the round.

The example deliberately does not include a map, weapons, teleporting, UI, or persistence. Those are game-specific concerns and remain outside the framework.

## Important boundary

RoundForge decides **who belongs to the round and which lifecycle state the server is in**. Your game decides what `Playing` means. In this example, `Humanoid.Died` is the elimination signal. A tag game, hot-potato game, survival game, or minigame can use a different signal without changing the round core.
