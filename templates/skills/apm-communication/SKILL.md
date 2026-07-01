---
name: apm-communication
description: Agent communication standards and file-based Message Bus protocol for structured inter-agent messaging.
---

# APM {VERSION} - Communication Skill

## 1. Overview

**Reading Agent:** Planner, Manager, Worker

This skill defines agent communication standards and the file-based Message Bus protocol. It covers communication models, bus identity, and shared message formats. Agent-specific delivery and reporting procedures are defined in each agent's guides.

Agents not managed by APM can participate in bus communication by creating their own agent directory under `.apm/bus/`. See `bus-integration.md` alongside this skill for the integration guide.

---

## 2. Agent-to-User Communication

### 2.1 Direct Communication

When communicating with the User - asking questions, requesting actions, providing status updates, presenting completions - use natural language adapted to the situation. Explain what happened, what was decided, and what happens next. There are no rigid templates; adapt phrasing to what the situation requires while conveying necessary information.

When directing Users to perform actions (run commands, switch chats, review artifacts), provide specific actionable guidance naturally: which command, in which agent's chat, with what arguments. Present commands the User needs to run in code blocks so they are easy to copy. Use inline code for file paths, values, and references within prose. When multiple actions are needed (open a new chat, run initiation, check tasks), list them clearly with enough spacing to distinguish each step. When the action requires a new chat, include the platform guidance per {NEW_CHAT_GUIDANCE}.

Communication at workflow transitions should orient the User: what was just completed, what comes next, and what action is needed. Adapt naturally to the moment rather than following a fixed format.

### 2.2 Visible Reasoning

At procedural decision points, present your analysis visibly in chat before acting. The User needs to understand why you are making each decision - explain your assessments, justify your choices, and surface trade-offs so they can review and audit your reasoning and redirect if needed. Reasoning quality correlates with output quality. Internal reasoning or thinking may reach conclusions before visible chat output begins - but visible analysis in chat must still walk through the reasoning that led to those conclusions. Present how you arrived at each decision, not just what you decided. The User cannot audit or redirect decisions that appear in chat as given.

When a procedure prescribes specific headers for reasoning, present those headers visibly and address each section beneath them. When a procedure describes aspects to cover without prescribing headers, cover all indicated aspects using whatever format suits the content - prose, lists, tables, or any combination. In both cases, the output is analysis presented for the User's review. When no reasoning frame is provided, present what you are assessing, the key considerations, and your conclusion.

### 2.3 Terminology Boundaries

Formal APM terms - consistently capitalized words in APM commands and guides like Task, Stage, Worker, Manager - are part of the agent's public vocabulary. Use them naturally when communicating. All other language is natural prose; standard English capitalization applies but confers no formal status.

The following are internal authoring structure - use them for navigation but never surface them in User-facing output:
- Section references (§N.M).
- Procedure names and named sections from your guides.
- Step labels and checkpoint names.
- Decision categories.

When transitioning between sections, describe what you are doing and why rather than announcing which section you are executing. Describe your findings and move naturally into the next topic rather than stating "Beginning [section name]" or "Entering [step name]."

Reasoning frame headers prescribed by your procedures are always surfaced as defined per §2.2 Visible Reasoning. These are analytical output structure, not section announcements.

### 2.4 Concise Autonomous Feedback

During Autonomous Mode polling, operator-facing chat follows three message categories. These rules apply **only when** `autonomous_mode_enabled` is true **and** the relevant polling flag is active (`polling_enabled` for Workers, `report_polling_enabled` for Managers). Manual Mode follows pre-004 conventions unchanged — do not apply wait-state suppression or compact heartbeat formats outside Autonomous Mode polling.

#### Message Categories

| Category | Purpose | Suppression | Examples |
|----------|---------|-------------|----------|
| **Wait-state** | Heartbeat while polling continues, no new bus content | Yes — per poll stretch + quiet interval | `{agent-slug}: checking task queue…` |
| **State-change** | Meaningful coordination transition | No — always emit | `Picked up Task 2.1`, `Report received from backend-agent (Task 2.1)` |
| **Substantive** | Audit-required content (review, errors, stops) | No — unchanged from 003 | Full review assessment, session end, coupling fallback |

**Visible reasoning carve-out:** §2.2 Visible Reasoning remains mandatory for review outcomes, dispatch decisions, planning modifications, errors, stop/handoff guidance, and coupling fallback. Wait-state heartbeats are status-only — not analytical reasoning. State-change messages are brief event announcements — may include one line of context but not full procedural walkthrough.

#### Wait-State Format

One line mandatory; optional second line on refresh only with elapsed hint. No internal procedure vocabulary (§ references, guide names, poll script identifiers) in wait-state or state-change lines.

**Poll script stdout is machine tokens only** (`STILL_EMPTY`, `WORK_FOUND`, `REPORT_FOUND`, `POLLING_STOPPED`). Poll scripts do **not** emit human-readable status lines — wait-state heartbeats live in agent chat only. Do **not** echo, quote, or summarize poll script stdout in chat on suppressed cycles. Do **not** label each poll iteration in chat (e.g. "Poll task bus cycle 3") — branch silently on stdout and emit wait-state only per suppression rules.

**Worker (initial):**
```text
{agent-slug}: checking task queue…
```

**Worker (refresh):**
```text
{agent-slug}: checking task queue…
(still waiting — {N}s)
```

**Manager (initial):**
```text
Manager: checking for reports…
```

**Manager (refresh):**
```text
Manager: checking for reports…
(still waiting — {N}s)
```

#### State-Change Format

Lead with what changed. Optional one-line context. Distinct from wait-state (event tone, not heartbeat).

| Event | Emitter | Required content | Timing |
|-------|---------|------------------|--------|
| Task picked up | Worker | Task id (+ Stage if applicable) | Before execution starts |
| Task completed | Worker | Task id; report availability | After report bus write |
| Report detected | Manager | Worker slug; Task id | Before review processing |
| Dispatch summary | Manager | Task id(s); target Worker slug(s) | After dispatch writes |
| Polling stopped | Either | Stop reason reference | Per 003 stop contracts |

**Examples:**
```text
Picked up Task 2.1 (Stage 2)
```
```text
Task 2.1 complete — report on Report Bus
```
```text
Report received from backend-agent (Task 2.1)
```
```text
Dispatched: Task 2.2 → backend-agent
```

#### Wait-State Suppression (Poll Stretch)

Track per poll stretch (consecutive `STILL_EMPTY` in one turn before a state-change or stop):

| Session attribute | Role | Purpose |
|-------------------|------|---------|
| `empty_poll_count` | Both | Consecutive empty polls since last state-change |
| `wait_state_sent` | Both | Whether initial wait-state was emitted this stretch |
| `last_wait_state_at` | Both | Best-effort timestamp or cycle index for refresh |

**On poll loop entry (Autonomous Mode):** Initialize `empty_poll_count = 0`, `wait_state_sent = false`, `last_wait_state_at = null`.

**On each `STILL_EMPTY` while polling flag is true:**

1. Increment `empty_poll_count`.
2. **IF** `wait_state_sent` is false: emit initial wait-state; set `wait_state_sent = true`; record `last_wait_state_at`.
3. **ELSE IF** quiet interval elapsed (`empty_poll_count >= APM_POLL_QUIET_CYCLES` **OR** elapsed seconds since `last_wait_state_at >= APM_POLL_QUIET_SECONDS`): emit refresh wait-state (may include elapsed hint); reset `empty_poll_count` to 0; update `last_wait_state_at`.
4. **ELSE:** Suppress chat output for this cycle.
5. **Always:** Re-invoke the poll script immediately — sleep is internal to the script; do not run a separate `sleep` command. Suppression affects chat only, not shell polling.

**Reset on state-change:** On `WORK_FOUND`, `REPORT_FOUND`, task completion, dispatch, or stop — reset `empty_poll_count`, `wait_state_sent`, `last_wait_state_at`; emit appropriate state-change message (not wait-state).

#### Operator Worker Init (Required Direct Communication)

**Scope:** Single-Worker, batch, and parallel dispatch — **always** when init applies. First dispatch at Stage start to one Worker still requires a fenced copy block; prose ("open a Worker chat") is not sufficient.

Task-delivery operator guidance is **not** wait-state and **not** suppressible. When dispatching to a Worker that is uninitialized, has polling stopped, or has no active Worker chat this session, **MUST** instruct the operator to run `{COMMAND_SLUG:work} <agent-id>` (or `{COMMAND_SLUG:task} <agent-id>` when appropriate).

**Parallel dispatch:** Never assume the operator already has all Worker chats open. For each Worker receiving a Task Prompt this turn, assess Worker tracking and include **every** Worker that is not actively polling in the copy block below — even when other Workers in the same parallel unit auto-pick without operator action.

**Default:** Unless Tracker Worker tracking confirms a Worker is **actively polling this session**, treat that Worker as requiring init and include it in the copy block. At Stage start or after project completion, parallel dispatch typically requires **all** dispatched Workers in the block.

#### Operator Worker Init Format (Required)

When any dispatched Worker requires init, emit init instructions **in the same turn as dispatch**, then **immediately** enter Report Queue Check (§3.8 step 3a) — **do not end the turn** and **do not wait** for the operator to open Worker chats first. Init instructions are copy-paste guidance while the Manager polls in parallel.

**Order (same turn, no stop between steps):**

1. **Dispatch summary** — one state-change line (Task ids and target Worker slugs).
2. **Per-Worker copy blocks** — for each Worker that is not actively polling, emit a **separate** fenced block (one Worker per fence — operator opens one new chat per block):

```text
content-agent — open a new chat and paste:

/apm.work content-agent
```

```text
quotes-facts-agent — open a new chat and paste:

/apm.work quotes-facts-agent
```

```text
animals-agent — open a new chat and paste:

/apm.work animals-agent
```

Optional: one-line Task id note outside each fence. Omit Workers already actively polling.

3. **Immediately poll** — without ending the turn, run `bash .apm/scripts/poll-report-bus.sh` (§3.8 step 3a). Reports arrive when Workers start; polling continues until `REPORT_FOUND`, stop, or §3.8.1 condition.

**Prohibited:**
- One combined fence listing all Workers — use **separate fences per Worker**.
- Ending the turn after init instructions without running the poll script.
- Waiting for operator confirmation before polling ("open these chats, then run `/apm.manage` again").
- Writing "Workers need initialization" without per-Worker fenced commands.
- Entering §3.8 step 3a before init blocks when any Worker requires init.

**Example (parallel — three Workers need init, same turn continues to poll):**
```text
Dispatched: Task 17.1 → content-agent; Task 17.2 → quotes-facts-agent; Task 17.3 → animals-agent

content-agent — open a new chat and paste:

/apm.work content-agent

quotes-facts-agent — open a new chat and paste:

/apm.work quotes-facts-agent

animals-agent — open a new chat and paste:

/apm.work animals-agent

Manager: checking for reports…
```

(Then poll script runs in the same turn — wait-state may follow §2.4 suppression.)

#### Coordination Turn Brevity During Polling

While `report_polling_enabled` or `polling_enabled` is true:

- **Wait-state only** during empty poll stretches — apply suppression; no other chat per cycle.
- **Do not** repeat execution-mode boilerplate, version-control recap, or session-state tables at every turn.
- **Do not** re-announce "Report Queue Check is active", "Work Queue Check is active", or similar procedure names while polling continues — use wait-state format instead.
- **Stop command** — show the stop-script code block **once** per poll-loop entry (first time entering §3.7/§3.8 this session or after operator asks how to stop). Do not repeat on every review-dispatch cycle or every turn while waiting.
- **After review-dispatch** entering poll wait: emit dispatch summary (if applicable), **per-Worker init copy blocks** (if any Worker requires init), then **immediately** poll in the same turn — not a full coordination re-brief, **never** end turn after init blocks.
- **Pending report** from a Worker without an active session: one line of direct communication naming the Worker and Task plus the `{COMMAND_SLUG:work}` command — not "I'll process when the report arrives" without the init command.

Substantive review assessments, errors, stops, and session-end messages remain full per §2.2 — brevity rules target polling repetition and procedural narration, not audit content.

#### Quiet Interval Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `APM_POLL_QUIET_CYCLES` | 5 | Empty poll chunks before refresh allowed |
| `APM_POLL_QUIET_SECONDS` | 60 | Wall-clock wait before refresh allowed |
| `APM_POLL_INTERVAL` | 10 | Seconds between internal checks within one poll script invocation |
| `APM_POLL_CHUNK_SECONDS` | 50 | Max wall time per poll script invocation (under Cursor ~60s shell limit) |

Either threshold triggering refresh satisfies the quiet interval ("whichever comes first").

For a poll stretch with ≥10 consecutive empty cycles: maximum wait-state emissions is **2** (initial + one refresh if quiet interval elapses).

#### Invalid Behaviors

- Skip poll script because wait-state was suppressed
- End turn after suppressed cycle
- Emit wait-state on every `STILL_EMPTY`
- Shorten substantive stop/error/review messages
- Apply suppression in Manual Mode
- Use wait-state chat as substitute for shell polling
- Omit `{COMMAND_SLUG:work}` instructions for parallel-dispatched Workers without active sessions
- Say "Workers need initialization" without per-Worker fenced `{COMMAND_SLUG:work}` copy blocks
- Combine all Workers in one fenced copy block — use separate fences per Worker
- End the turn after Operator Worker Init without immediately running `poll-report-bus.sh` in the same turn
- Wait for operator to open Worker chats or re-run `{COMMAND_SLUG:manage}` before polling
- Enter Report Queue Check or run `poll-report-bus.sh` before emitting Operator Worker Init when any dispatched Worker requires init
- Repeat stop-script blocks or "Report Queue Check is active" every turn while polling
- End a coordination turn with polling narration instead of running the poll loop or giving required Worker init commands
- Echo or narrate poll script stdout (`STILL_EMPTY`, etc.) on every cycle — stdout appears in tool results; chat wait-state follows suppression rules only
- Label each poll chunk in chat ("Poll task bus cycle N", "Wait between task bus polls") — poll silently except for suppressed wait-state heartbeats; one tool block per script invocation
- Run `sleep` as a separate shell command between poll script invocations — the poll script sleeps internally

---

## 3. Agent-to-System Communication

When writing to APM artifacts (Spec, Plan, Tracker, Task Logs, bus files), follow the structural format defined by the relevant guide's structural specifications section or the bus protocol in §4 Message Bus Protocol. Artifact content is technical, formal, structured, and precise. Internal procedure vocabulary does not appear in artifacts - use natural descriptive language for any free-text fields.

---

## 4. Message Bus Protocol

Bus directories and files are initialized during the Planning Phase. Bus files are either empty (no message present) or contain a message awaiting delivery. Before writing to an outgoing bus file, an agent clears its incoming bus file. Always read a bus file before writing to it - this ensures the platform's file tools recognize the file and avoids write failures on empty or cleared files.

### 4.1 Bus Identity Standards

Agent identity is derived from the agent directory name (`.apm/bus/<agent-slug>/`). Workers validate by confirming the directory matches their registered `agent`. If the agent directory does not match, reject the message and inform the User of the mismatch.

### 4.2 Agent ID Resolution

When `{COMMAND_SLUG:task}` or `{COMMAND_SLUG:review}` accept an `[agent-id]` argument, resolve it against `.apm/bus/` directory names: exact match, then prefix, then best plausible match. When only one plausible candidate exists, resolve to it. When multiple candidates are plausible, list them and ask the User. When no bus directories exist, inform that the Message Bus is not initialized.

### 4.3 Agent Slug Format

Agent slugs are derived from the Worker names listed in the Plan Workers field by converting to lowercase and replacing spaces with hyphens. Examples: `Frontend Agent` → `frontend-agent`, `Backend Agent` → `backend-agent`. The Manager's own directory uses the slug `manager`.

---

**End of Skill**
