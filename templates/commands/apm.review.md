---
command_name: review
description: Review Task Reports from the Report Bus.
---

# APM {VERSION} - Manager Review Command

Review Task Reports from Worker Report Buses. If you are a Planner, Worker, or non-APM agent, concisely decline and take no action.

**Primary Manual Mode path (FR-008):** When Autonomous Mode is inactive (default), this command is the **primary** review path at the review boundary. After dispatch, the Manager instructs the operator to run `{COMMAND_SLUG:review}` — the Manager does not enter Report Queue Check (§3.8).

**Autonomous Mode fallback:** When Autonomous Mode is active, reports are detected via Report Queue Check (`{GUIDE_PATH:task-review}` §3.8) and this command is not required at the review boundary. Use this command when Autonomous Mode has stopped or is inactive — after queue checking was stopped, in a new Manager session before dispatch resumes §3.8, when Autonomous Mode has ended, or when the operator wants explicit control at any review boundary.

Accepts optional `[agent-id ...]` arguments. With arguments, checks those Workers' Report Buses. Without arguments, checks Workers with active dispatches plus a health check for unexpected content.

**Procedure:**
1. Determine scan scope:
   - If `{ARGS}` provided, resolve each agent-id per `{SKILL_PATH:apm-communication}` §4.2 Agent ID Resolution. Batch-read all targeted Report Buses in a single terminal invocation, e.g., `cat .apm/bus/<slug-1>/report.md .apm/bus/<slug-2>/report.md` (or platform equivalent). Continue to step 3.
   - If no argument, continue to step 2.

2. Scan Report Buses: scan and read all Report Buses in a single terminal invocation, e.g., `for f in .apm/bus/*/report.md; do [ -s "$f" ] && echo "=== $f ===" && cat "$f"; done` (or platform equivalent). This discovers non-empty buses, reads their content, and includes path markers for cross-referencing against active dispatches. If any unexpected bus has content (beyond the actively dispatched Workers), include it and inform the User. If no buses have content, inform User that no pending reports are available. Await next invocation. If one or more have content, continue to step 3 for each.

3. Process report(s): for each Report Bus with content, process per `{GUIDE_PATH:task-review}` §3 Task Review Procedure. Equivalent to entering Report Queue Check at the process-reports step — use the same review standards; polling loop behavior in §3.8 does not apply unless operator re-engages continuous coordination.

---

**End of Command**
