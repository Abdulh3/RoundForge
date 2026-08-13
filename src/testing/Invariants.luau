--!strict

local Invariants = {}

export type CheckResult = {
    name: string,
    passed: boolean,
    message: string?,
}

local VALID_STATES = {
    Waiting = true,
    Intermission = true,
    Preparing = true,
    Playing = true,
    Finished = true,
}

function Invariants.validState(snapshot: any): CheckResult
    local passed = VALID_STATES[snapshot.state] == true
    return {
        name = "valid-state",
        passed = passed,
        message = if passed then nil else "unknown state: " .. tostring(snapshot.state),
    }
end

function Invariants.roundLockMatchesState(snapshot: any): CheckResult
    local shouldBeLocked = snapshot.state == "Preparing" or snapshot.state == "Playing" or snapshot.state == "Finished"
    local passed = snapshot.roundLocked == shouldBeLocked

    return {
        name = "round-lock-matches-state",
        passed = passed,
        message = if passed then nil else string.format(
            "state=%s roundLocked=%s",
            tostring(snapshot.state),
            tostring(snapshot.roundLocked)
        ),
    }
end

function Invariants.winnerOnlyAfterPlay(snapshot: any): CheckResult
    local passed = snapshot.winnerId == nil or snapshot.state == "Finished"
    return {
        name = "winner-only-after-play",
        passed = passed,
        message = if passed then nil else "winner exists outside Finished state",
    }
end

function Invariants.nonNegativeRemaining(snapshot: any): CheckResult
    local passed = snapshot.remaining == nil or snapshot.remaining >= 0
    return {
        name = "non-negative-remaining-time",
        passed = passed,
        message = if passed then nil else "remaining time is negative",
    }
end

function Invariants.runCore(snapshot: any): { CheckResult }
    return {
        Invariants.validState(snapshot),
        Invariants.roundLockMatchesState(snapshot),
        Invariants.winnerOnlyAfterPlay(snapshot),
        Invariants.nonNegativeRemaining(snapshot),
    }
end

return Invariants
