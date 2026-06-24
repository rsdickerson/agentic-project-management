---
command_name: autonomous
description: Enable, disable, or check status of APM Autonomous Execution Mode.
---

# APM {VERSION} - Autonomous Execution Mode Command

Manage **Autonomous Execution Mode** — the opt-in paired Worker task polling and Manager report checking capability. Manual Mode remains the default when Autonomous Mode is not active.

Read `{SKILL_PATH:apm-autonomous}` for full mode semantics, coupling invariants, and stop behavior.

---

## 1. Overview

Autonomous Mode activates when `.cursor/rules/apm-autonomous.mdc` is present in the project and declares Autonomous Execution Mode active. The rule is **not installed by default** — operators opt in explicitly.

| Mode | Indicator | Polling behavior |
|------|-----------|------------------|
| Manual (default) | Rule absent or disabled | No automatic §3.7 / §3.8 entry |
| Autonomous | Rule present and active | Paired Worker + Manager poll loops |

**Mode re-detection:** Enabling or disabling the rule does not change active poll loops immediately. Manager and Worker sessions re-read mode at session init (`{GUIDE_PATH:task-execution}` §2.8, `{GUIDE_PATH:task-review}` §2.13) and at the next §3.7 / §3.8 entry. Active autonomous sessions fall back to Manual Mode at the next poll entry or when stop scripts run.

---

## 2. Procedure

Parse `{ARGS}` for subcommand: `enable`, `disable`, or `status` (default: `status` if no argument or unrecognized input).

### 2.1 Status

1. Check whether `.cursor/rules/apm-autonomous.mdc` exists.
2. If present, read the file and confirm it declares **Autonomous Execution Mode active** (not merely an empty or unrelated rule).
3. Report to the operator:
   - **Active:** Autonomous Mode enabled — Manager and Worker sessions will use paired polling when gates apply. Next `{COMMAND_SLUG:manage}` or `{COMMAND_SLUG:work}` init re-detects mode.
   - **Inactive:** Manual Mode — operator triggers `{COMMAND_SLUG:review}` and `{COMMAND_SLUG:task}` / `{COMMAND_SLUG:work}` at boundaries.
4. Note whether `{SKILL_PATH:apm-autonomous}` is available in `{SKILLS_DIR}/`.
5. If a Manager or Worker session may already be polling, remind the operator that removing the rule or running `disable` takes effect at the next poll entry; use stop scripts to end active loops immediately (see §2.3).

### 2.2 Enable

1. Locate the rule template (first path that exists):
   - `templates/rules/apm-autonomous.mdc` (APM source / post-`apm update` project root)
   - Same path relative to repository root when developing APM itself
2. If no template is found, inform the operator to run `apm update` (or project-equivalent) to install APM templates, then retry.
3. Create `.cursor/rules/` if missing.
4. Copy the rule template to `.cursor/rules/apm-autonomous.mdc`:

   ```bash
   mkdir -p .cursor/rules
   cp templates/rules/apm-autonomous.mdc .cursor/rules/
   ```

5. Confirm Autonomous Mode is now active for the project.
6. Inform the operator:
   - Start or continue coordination with `{COMMAND_SLUG:manage}` (Manager) and `{COMMAND_SLUG:work}` (Worker) — mode is re-detected at session init and at §3.7 / §3.8 entry.
   - Both Manager and Worker must participate — mismatch falls back to Manual Mode per `{SKILL_PATH:apm-autonomous}` §4 and `{GUIDE_PATH:task-execution}` §2.9 / `{GUIDE_PATH:task-review}` §2.14.
   - Manual commands remain valid fallbacks when autonomous coordination stops.

### 2.3 Disable

1. Remove the project rule if present:

   ```bash
   rm -f .cursor/rules/apm-autonomous.mdc
   ```

2. Confirm Autonomous Mode is disabled. Manual Mode is now the project default.
3. Inform the operator:
   - **Active polling sessions:** Fall back to Manual Mode at the next §3.7 or §3.8 entry (mode coupling re-check reads absent rule). To stop immediately, run stop scripts in a terminal:
     - Worker: `bash .apm/scripts/stop-task-polling.sh <agent-slug>`
     - Manager: `bash .apm/scripts/stop-report-polling.sh`
   - Stopping emits the autonomous session end message per `{GUIDE_PATH:task-execution}` §3.7.3 and `{GUIDE_PATH:task-review}` §3.8.2.
   - Continue coordination manually via `{COMMAND_SLUG:review}`, `{COMMAND_SLUG:task}`, and `{COMMAND_SLUG:work}`.
   - Re-enable anytime with `{COMMAND_SLUG:autonomous} enable` or by restoring the rule file.

---

## 3. Operating Notes

- Enabling or disabling the rule does **not** modify poll scripts (`.apm/scripts/poll-task-bus.sh`, `.apm/scripts/poll-report-bus.sh`).
- Mode detection runs at session init and at §3.7 / §3.8 entry per `{GUIDE_PATH:task-execution}` §2.8 and `{GUIDE_PATH:task-review}` §2.13.
- Disabling mid-session is equivalent to removing the rule — coupling checks at poll entry detect `rule_not_active` and fall back to Manual Mode with the session end message.
- Re-read `{SKILL_PATH:apm-autonomous}` when explaining mode behavior to the operator.

---

**End of Command**
