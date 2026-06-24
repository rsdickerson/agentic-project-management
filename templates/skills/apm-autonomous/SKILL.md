---
name: apm-autonomous
description: Autonomous Execution Mode semantics — paired Worker/Manager polling, Manual Mode fallback, coupling invariants, and stop behavior.
---

# APM {VERSION} - Autonomous Execution Mode Skill

## 1. Overview

**Reading Agent:** Manager, Worker, Operator (via `{COMMAND_PATH:apm.autonomous}`)

This skill defines **Autonomous Execution Mode** — a single opt-in coordination mode in which Worker task polling (Work Queue Check) and Manager report checking (Report Queue Check) operate as an **inseparable paired loop**. Manual Mode is the default when this mode is not active.

---

## 2. Execution Modes

### 2.1 Manual Mode (Default)

| Aspect | Behavior |
|--------|----------|
| Activation | Default when `.cursor/rules/apm-autonomous.mdc` is absent |
| Manager after dispatch | Instruct operator to run `{COMMAND_SLUG:review}` when Workers report |
| Worker after completion | Deliver report; next work via `{COMMAND_SLUG:task}` or `{COMMAND_SLUG:work}` |
| Polling loops | **Not entered** — §3.7 and §3.8 are skipped |
| Operator control | Step-by-step at review and task-delivery boundaries |

### 2.2 Autonomous Mode (Opt-In)

| Aspect | Behavior |
|--------|----------|
| Activation | `.cursor/rules/apm-autonomous.mdc` present with Autonomous Mode declaration |
| Manager after dispatch | Enter `{GUIDE_PATH:task-review}` §3.8 Report Queue Check automatically |
| Worker after completion | Enter `{GUIDE_PATH:task-execution}` §3.7 Work Queue Check automatically |
| Polling loops | **Both active** as a paired system |
| Operator control | Stop buttons, Handoff, explicit disable; no boundary commands between Tasks |

### 2.3 Command Roles by Mode

| Command | Manual Mode | Autonomous Mode |
|---------|-------------|-----------------|
| `{COMMAND_SLUG:manage}` | Dispatch + manual review instruction | Dispatch + auto report checking |
| `{COMMAND_SLUG:work}` | Single assignment execution | Execution + auto task polling |
| `{COMMAND_SLUG:review}` | **Primary** review path | Fallback when autonomous stopped |
| `{COMMAND_SLUG:task}` | **Primary** next-task delivery | Fallback / init trigger |
| `{COMMAND_SLUG:autonomous}` | Enable Autonomous Mode | Disable or show status |

---

## 3. Session Attributes

| Attribute | Role | Manual default | Autonomous default |
|-----------|------|----------------|---------------------|
| `autonomous_mode_enabled` | Both | false | true |
| `polling_enabled` | Worker | false | true when entering §3.7 |
| `report_polling_enabled` | Manager | false | true when entering §3.8 |

**Invariants:**

1. `polling_enabled` MUST NOT be true unless `autonomous_mode_enabled` is true.
2. `report_polling_enabled` MUST NOT be true unless `autonomous_mode_enabled` is true.
3. §3.7 and §3.8 MUST NOT run when `autonomous_mode_enabled` is false.

Detection procedure: `{GUIDE_PATH:task-execution}` §2.8 and `{GUIDE_PATH:task-review}` §2.13.

---

## 4. Mode Coupling (Paired Loop Invariant)

Worker task polling **requires** Manager report checking capability, and vice versa. When Autonomous Mode is active, **both** MUST be enabled together. Partial autonomous loops are invalid.

**Mode coupling check** (at §3.7 and §3.8 entry when `autonomous_mode_enabled` is true):

1. IF project `apm-autonomous` rule absent or ambiguous → **coupling fail**
2. IF entering §3.7 AND no evidence Manager will participate in autonomous coordination → **coupling fail**
3. IF entering §3.8 AND target Worker(s) not initialized → **coupling ok with wait-state notice** (not a hard fail)
4. ELSE → **coupling ok**

**On coupling fail:**

```
Autonomous Mode requires both Manager and Worker participation.
Falling back to Manual Mode for this session.
```

Then set `autonomous_mode_enabled`, `polling_enabled`, and `report_polling_enabled` to false. Use Manual Mode paths — do NOT run a partial autonomous loop.

---

## 5. Poll-Until-Stop (FR-017)

When Worker task polling or Manager report checking **is active** (Autonomous Mode on, or features 001/002 behavior before Autonomous gates are deployed), agents MUST use a **same-turn check/wait/check cycle** on empty bus results:

- Continue until work or a report arrives **OR** a defined stop condition fires.
- **Do NOT** end the conversation turn after a single empty check (`STILL_EMPTY`) or idle announcement while polling remains active.
- An empty Task Bus or Report Bus alone is **NOT** a stop condition.

**Valid stop conditions** include: operator stop script, operator explicit stop in chat, Handoff initiation, session context threshold (~75%), coordination complete (no active Workers and no pending reports), fail-fast batch failure, and other stops defined in features 001 and 002.

Poll scripts (`.apm/scripts/poll-task-bus.sh`, `.apm/scripts/poll-report-bus.sh`) are called repeatedly in a same-turn agent loop with `sleep ${APM_POLL_INTERVAL:-10}` between empty checks — not one long-running bash process.

---

## 6. Autonomous Session End (FR-010)

When autonomous coordination stops (any stop condition, rule removal, or mismatch fallback), both roles emit:

```
Autonomous session has ended.
You may:
- Re-enable Autonomous Mode (ensure apm-autonomous rule is active, then continue with /apm.manage or /apm.work)
- Switch to manual coordination (/apm.review, /apm.task, /apm.work)
```

Preserve unprocessed Report Bus content, queued Task Bus assignments, and Tracker state.

**Re-enable:** Ensure `.cursor/rules/apm-autonomous.mdc` is present, then operator runs `{COMMAND_SLUG:manage}` or `{COMMAND_SLUG:work}` — mode is re-read at session init / poll entry.

---

## 7. Shared Stop Conditions (FR-011)

When active in Autonomous Mode, inherit stop conditions from Worker work-polling and Manager report-polling without weakening safeguards:

| Stop | Worker | Manager |
|------|--------|---------|
| No active Workers + no pending reports | N/A | Stop §3.8 |
| Context threshold (~75%) | Stop §3.7; recommend Handoff | Stop §3.8; recommend Handoff |
| Operator Handoff | Follow Handoff guide | Follow Handoff guide |
| Explicit operator stop | `stop-task-polling.sh` | `stop-report-polling.sh` |
| Fail-fast batch failure | Per batch rules | Per review outcome |

---

**End of Skill**
