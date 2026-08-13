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

local function setFromArray(values: { any }): { [any]: boolean }
    local result = {}

    for _, value in values do
        result[value] = true
    end

    return result
end

function Invariants.validState(snapshot: any): CheckResult
    local passed = VALID_STATES[snapshot.state] == true

    return {
        name = "valid-state",
        passed = passed,
        message = if passed then nil else "unknown state: " .. tostring(snapshot.state),
    }
end

function Invariants.roundLockMatchesState(snapshot: any): CheckResult
    local shouldBeLocked =
        snapshot.state == "Preparing"
        or snapshot.state == "Playing"
        or snapshot.state == "Finished"

    local passed = snapshot.roundLocked == shouldBeLocked

    return {
        name = "round-lock-matches-state",
        passed = passed,
        message = if passed
            then nil
            else string.format(
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

function Invariants.winnerBelongsToRound(snapshot: any): CheckResult
    if snapshot.winnerId == nil then
        return {
            name = "winner-belongs-to-round",
            passed = true,
        }
    end

    local participants = setFromArray(snapshot.roundParticipantIds or {})
    local passed = participants[snapshot.winnerId] == true

    return {
        name = "winner-belongs-to-round",
        passed = passed,
        message = if passed then nil else "winner is missing from the active round snapshot",
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

function Invariants.countsMatchIds(snapshot: any): CheckResult
    local connected = snapshot.connectedIds or {}
    local roundParticipants = snapshot.roundParticipantIds or {}
    local lateJoiners = snapshot.lateJoinerIds or {}

    local passed =
        #connected == snapshot.connectedCount
        and #roundParticipants == snapshot.roundCount
        and #lateJoiners == snapshot.lateJoinerCount

    return {
        name = "counts-match-id-snapshots",
        passed = passed,
        message = if passed
            then nil
            else string.format(
                "connected=%d/%s round=%d/%s late=%d/%s",
                #connected,
                tostring(snapshot.connectedCount),
                #roundParticipants,
                tostring(snapshot.roundCount),
                #lateJoiners,
                tostring(snapshot.lateJoinerCount)
            ),
    }
end

function Invariants.lateJoinersAreDisjoint(snapshot: any): CheckResult
    local participants = setFromArray(snapshot.roundParticipantIds or {})
    local overlap = nil

    for _, id in snapshot.lateJoinerIds or {} do
        if participants[id] then
            overlap = id
            break
        end
    end

    return {
        name = "late-joiners-disjoint-from-round",
        passed = overlap == nil,
        message = if overlap == nil
            then nil
            else "participant appears in both round and late-join sets: " .. tostring(overlap),
    }
end

function Invariants.waitingHasNoRoundResidue(snapshot: any): CheckResult
    if snapshot.state ~= "Waiting" then
        return {
            name = "waiting-has-no-round-residue",
            passed = true,
        }
    end

    local passed =
        snapshot.roundLocked == false
        and snapshot.roundCount == 0
        and snapshot.lateJoinerCount == 0
        and snapshot.winnerId == nil
        and snapshot.deadline == nil

    return {
        name = "waiting-has-no-round-residue",
        passed = passed,
        message = if passed then nil else "Waiting state contains locked-round residue",
    }
end

function Invariants.minimumPlayersWhileActive(snapshot: any): CheckResult
    local active = snapshot.state == "Preparing" or snapshot.state == "Playing"

    if not active then
        return {
            name = "minimum-players-while-active",
            passed = true,
        }
    end

    local passed = snapshot.roundCount >= snapshot.minimumPlayers

    return {
        name = "minimum-players-while-active",
        passed = passed,
        message = if passed
            then nil
            else string.format(
                "active round has %d participants but requires %d",
                snapshot.roundCount,
                snapshot.minimumPlayers
            ),
    }
end

function Invariants.runCore(snapshot: any): { CheckResult }
    return {
        Invariants.validState(snapshot),
        Invariants.roundLockMatchesState(snapshot),
        Invariants.winnerOnlyAfterPlay(snapshot),
        Invariants.winnerBelongsToRound(snapshot),
        Invariants.nonNegativeRemaining(snapshot),
        Invariants.countsMatchIds(snapshot),
        Invariants.lateJoinersAreDisjoint(snapshot),
        Invariants.waitingHasNoRoundResidue(snapshot),
        Invariants.minimumPlayersWhileActive(snapshot),
    }
end

return Invariants
