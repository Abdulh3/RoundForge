--!strict

local Reporter = {}

export type CheckDetail = {
    name: string,
    passed: boolean,
    message: string?,
    checkpoint: string?,
    state: string?,
}

export type TraceEntry = {
    label: string,
    at: number?,
    snapshot: any,
}

export type Report = {
    scenario: string,
    result: "passed" | "failed",
    checks: number,
    failures: number,
    checkpoints: number,
    seed: number?,
    details: { CheckDetail },
    trace: { TraceEntry },
}

function Reporter.fromCheckpoints(
    scenario: string,
    checkpoints: { any },
    seed: number?
): Report
    local failures = 0
    local checkCount = 0
    local details = {}
    local trace = {}

    for _, checkpoint in checkpoints do
        table.insert(trace, {
            label = checkpoint.label,
            at = checkpoint.at,
            snapshot = checkpoint.snapshot,
        })

        for _, check in checkpoint.checks do
            checkCount += 1

            if check.passed ~= true then
                failures += 1
            end

            table.insert(details, {
                name = check.name,
                passed = check.passed == true,
                message = check.message,
                checkpoint = checkpoint.label,
                state = checkpoint.snapshot and checkpoint.snapshot.state or nil,
            })
        end
    end

    return {
        scenario = scenario,
        result = if failures == 0 then "passed" else "failed",
        checks = checkCount,
        failures = failures,
        checkpoints = #checkpoints,
        seed = seed,
        details = details,
        trace = trace,
    }
end

function Reporter.combine(name: string, reports: { Report })
    local failures = 0
    local checks = 0
    local checkpoints = 0

    for _, report in reports do
        failures += report.failures
        checks += report.checks
        checkpoints += report.checkpoints
    end

    return {
        scenario = name,
        result = if failures == 0 then "passed" else "failed",
        checks = checks,
        failures = failures,
        checkpoints = checkpoints,
        reports = reports,
    }
end

function Reporter.assertPassed(report: any)
    if report.result == "passed" then
        return
    end

    local messages = {}

    if report.details ~= nil then
        for _, detail in report.details do
            if not detail.passed then
                table.insert(
                    messages,
                    string.format(
                        "[%s / %s] %s: %s",
                        detail.checkpoint or "?",
                        detail.state or "?",
                        detail.name,
                        detail.message or "failed"
                    )
                )
            end
        end
    elseif report.reports ~= nil then
        for _, child in report.reports do
            if child.result ~= "passed" then
                table.insert(
                    messages,
                    string.format(
                        "%s: %d failure(s)",
                        child.scenario,
                        child.failures
                    )
                )
            end
        end
    end

    error("RoundForge QA failed:\n" .. table.concat(messages, "\n"), 2)
end

return Reporter
