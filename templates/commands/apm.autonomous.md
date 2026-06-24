---
command_name: autonomous
description: Enable, disable, or check status of APM Autonomous Execution Mode.
---

# APM {VERSION} - Autonomous Execution Mode Command

Manage **Autonomous Execution Mode** — the opt-in paired Worker task polling and Manager report checking capability. Manual Mode remains the default when Autonomous Mode is not active.

Read `{SKILL_PATH:apm-autonomous}` for full mode semantics, coupling invariants, and stop behavior.

---

## 1. Overview

Autonomous Mode activates when `.cursor/rules/apm-autonomous.mdc` is present in the project. The rule is **not installed by default** — operators opt in explicitly.

| Mode | Indicator | Polling behavior |
|------|-----------|------------------|
| Manual (default) | Rule absent | No automatic §3.7 / §3.8 entry |
| Autonomous | Rule present | Paired Worker + Manager poll loops |

---

## 2. Procedure

Parse `{ARGS}` for subcommand: `enable`, `disable`, or `status` (default: `status` if no argument or unrecognized input).

### 2.1 Status

1. Check whether `.cursor/rules/apm-autonomous.mdc` exists.
2. Report to the operator:
   - **Active:** Autonomous Mode enabled — Manager and Worker sessions will use paired polling when gates apply.
   - **Inactive:** Manual Mode — operator triggers `{COMMAND_SLUG:review}` and `{COMMAND_SLUG:task}` / `{COMMAND_SLUG:work}` at boundaries.
3. Note whether `{SKILL_PATH:apm-autonomous}` is available in `{SKILLS_DIR}/`.

### 2.2 Enable

1. Verify rule template exists at `templates/rules/apm-autonomous.mdc` (shipped with APM) or in the repository source at the same path.
2. Create `.cursor/rules/` if missing.
3. Copy the rule template to `.cursor/rules/apm-autonomous.mdc`:

   ```bash
   mkdir -p .cursor/rules
   cp templates/rules/apm-autonomous.mdc .cursor/rules/
   ```

4. Confirm Autonomous Mode is now active for **new and continuing sessions** after mode re-detection at next `{COMMAND_SLUG:manage}` or `{COMMAND_SLUG:work}` init (or at next poll entry).
5. Remind the operator: both Manager and Worker must participate — mismatch falls back to Manual Mode per `{SKILL_PATH:apm-autonomous}` §4.

### 2.3 Disable

1. Remove the project rule if present:

   ```bash
   rm -f .cursor/rules/apm-autonomous.mdc
   ```

2. Confirm Autonomous Mode is disabled. Manual Mode is now default.
3. Inform the operator that active polling sessions will fall back to Manual Mode at next poll entry; use `{COMMAND_SLUG:review}`, `{COMMAND_SLUG:task}`, and `{COMMAND_SLUG:work}` for manual coordination.

---

## 3. Operating Notes

- Enabling or disabling the rule does **not** modify poll scripts (`.apm/scripts/poll-task-bus.sh`, `.apm/scripts/poll-report-bus.sh`).
- Mode detection runs at session init and at §3.7 / §3.8 entry per `{GUIDE_PATH:task-execution}` §2.8 and `{GUIDE_PATH:task-review}` §2.13.
- Re-read `{SKILL_PATH:apm-autonomous}` when explaining mode behavior to the operator.

---

**End of Command**
