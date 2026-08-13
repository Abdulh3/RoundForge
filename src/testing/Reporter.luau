--!strict

local Reporter = {}

export type Report = {
    result: "passed" | "failed",
    checks: number,
    failures: number,
    details: { any },
}

function Reporter.fromChecks(checks: { any }): Report
    local failures = 0
    local details = {}

    for _, check in checks do
        if check.passed ~= true then
            failures += 1
        end

        table.insert(details, {
            name = check.name,
            passed = check.passed == true,
            message = check.message,
        })
    end

    return {
        result = if failures == 0 then "passed" else "failed",
        checks = #checks,
        failures = failures,
        details = details,
    }
end

function Reporter.assertPassed(report: Report)
    if report.result == "passed" then
        return
    end

    local messages = {}
    for _, detail in report.details do
        if not detail.passed then
            table.insert(messages, string.format("%s: %s", detail.name, detail.message or "failed"))
        end
    end

    error("RoundForge QA failed:\n" .. table.concat(messages, "\n"), 2)
end

return Reporter
