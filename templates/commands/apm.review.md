---
command_name: review
description: Review Task Reports from the Report Bus.
---

# APM {VERSION} - Manager Review Command

Review Task Reports from Worker Report Buses. If you are a Planner, Worker, or non-APM agent, concisely decline and take no action.

**Manual fallback:** Use this command when Manager report polling is not active — after polling was stopped, in a new Manager session before dispatch resumes polling, or when the operator wants explicit control. When the Manager is actively polling per `{GUIDE_PATH:task-review}` §3.8 Report Queue Check Procedure, reports are detected automatically and this command is not required at the review boundary.

Accepts optional `[agent-id ...]` arguments. With arguments, checks those Workers' Report Buses. Without arguments, checks Workers with active dispatches plus a health check for unexpected content.

**Procedure:**
1. Determine scan scope:
   - If `{ARGS}` provided, resolve each agent-id per `{SKILL_PATH:apm-communication}` §4.2 Agent ID Resolution. Batch-read all targeted Report Buses in a single terminal invocation, e.g., `cat .apm/bus/<slug-1>/report.md .apm/bus/<slug-2>/report.md` (or platform equivalent). Continue to step 3.
   - If no argument, continue to step 2.

2. Scan Report Buses: scan and read all Report Buses in a single terminal invocation, e.g., `for f in .apm/bus/*/report.md; do [ -s "$f" ] && echo "=== $f ===" && cat "$f"; done` (or platform equivalent). This discovers non-empty buses, reads their content, and includes path markers for cross-referencing against active dispatches. If any unexpected bus has content (beyond the actively dispatched Workers), include it and inform the User. If no buses have content, inform User that no pending reports are available. Await next invocation. If one or more have content, continue to step 3 for each.

3. Process report(s): for each Report Bus with content, process per `{GUIDE_PATH:task-review}` §3 Task Review Procedure. Equivalent to entering Report Queue Check at the process-reports step — use the same review standards; polling loop behavior in §3.8 does not apply unless operator re-engages continuous coordination.

---

**End of Command**
