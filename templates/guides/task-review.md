# APM {VERSION} - Task Review Guide

## 1. Overview

**Reading Agent:** Manager

This guide defines how you review Task results, determine review outcomes, modify planning documents when findings warrant it, and maintain the Tracker.

### 1.1 Outputs

- *Stage summaries:* Appended to the Index after each Stage completion.
- *Updated Tracker:* Updated after each review cycle to reflect Task state changes, readiness changes, merge state, and coordination context.
- *Modified planning documents:* When findings warrant it - updated Spec, Plan, or Rules.

---

## 2. Operational Standards

### 2.1 Task Log Review Standards

Extract the information needed for the next review decision.

**Status interpretation:** Assess whether the status and flags are consistent with the log's body content - inconsistency is a hallucination indicator. Status values are Success (objective achieved, all validation passed), Partial (progress made, needs guidance), Failed (objective not achieved).

**Flag interpretation.** Workers set flags based on scoped observations. Interpret with full project awareness:
- `important_findings: true` - Worker observed something potentially beyond Task scope. Assess whether it affects planning documents or other Tasks. When findings indicate that validation criteria from the Task Prompt were not fully exercised, this warrants investigation before marking Done. Important findings may also include User corrections noted as potential Rules entries - assess whether they warrant a Rules addition per §2.3 Planning Document Modification Standards.
- `compatibility_issues: true` - Worker observed conflicts with existing systems. Assess whether it indicates Plan, Spec, or Rules issues.

**Content review:** Beyond flags and status, review the log body sections (Summary, Details, Output, Validation, Issues) to understand what happened and inform the review outcome. When findings contradict content in the Spec, Plan, or Rules - factual inaccuracies, incorrect assumptions, outdated descriptions - treat the affected document as needing correction per §3.4 Planning Document Modification regardless of whether the Worker handled the discrepancy.

### 2.2 Review Outcome Standards

After reviewing a Task Log, determine the review outcome.

**Review the log:** If everything looks good - Success status with no flags, log content supports the status - proceed to Task Tracking updates. If something needs attention - flags raised, non-Success status, or inconsistencies - investigate before proceeding.

**Investigation scope:** Investigate directly for contained checks; use a subagent for context-intensive issues. When scope is unclear, prefer subagent to preserve Manager context. When a subagent returns findings, verify critical claims by reading the key files it references before acting on them. {MANAGER_SUBAGENT_GUIDANCE}

**Post-investigation outcome:**
- If no issues are found (false positives, nothing actionable), continue to the next Task(s).
- If the Worker needs to retry with refined instructions, create a follow-up Task Prompt per `{GUIDE_PATH:task-assignment}` §3.4 Follow-Up Task Prompt Construction. If the Worker also left changes uncommitted, note this in the follow-up instructions.
- If planning documents need modification, proceed to §3.4 Planning Document Modification.
- If investigation reveals deficiencies in previously-Done work, create a new Task through Plan modification per §2.3 Planning Document Modification Standards. The original Task remains Done; reference it from the new Task, include the discovery context, and specify what needs correction.

Small contained actions (follow-ups for isolated issues, minor planning document corrections) can be executed immediately during the review cycle - present findings to the User for awareness after acting. When changes are significant enough to affect project direction or scope, pause for User approval per §2.3 Planning Document Modification Standards.

### 2.3 Planning Document Modification Standards

**Cascade reasoning:** Spec and Plan have bidirectional influence - changes to one may require adjustments in the other. Rules are generally isolated. When modifying any document, assess cascade implications before executing. Distinguish execution adjustments within design intent (no cascade) from design assumptions that proved incorrect (cascade warranted). When uncertain, assess the related document rather than assuming isolation.

**Modification authority:** Small contained changes are Manager authority (single Task clarification or correction, adding a missing dependency, isolated Spec addition, minor Rules adjustment). Significant changes require User collaboration (multiple Tasks affected, design direction change, scope expansion or reduction, new Stage or major restructure). Multiple small modifications that together represent significant change require User collaboration. When authority is unclear, prefer User collaboration.

### 2.4 Parallel Coordination Standards

When multiple Workers are active simultaneously, coordinate asynchronously.

**Immediate reassessment:** After processing each report, reassess readiness and continue to dispatch assessment in the same turn - review and next dispatch happen in a single response without waiting for User input. The only reasons to pause are when no Tasks are Ready (wait state) or when a modification requires User collaboration per §2.2 Review Outcome Standards.

**Async report handling:** Reports arrive in any order. Process each as it comes - complete the review, merge if needed, reassess readiness, dispatch newly Ready Tasks. Each report-to-dispatch cycle is continuous.

**Merge coordination:** After successful review during parallel dispatch, merge the completed Task's branch per §2.5 Merge Standards before dispatching dependent Tasks. At Stage end, perform a merge sweep per §2.5 Merge Standards.

**Wait state:** When no Tasks are Ready but Workers are active, communicate what was processed, what is pending, and which report(s) the User should return next. If a pending report would unlock a better dispatch combination per `{GUIDE_PATH:task-assignment}` §2.4 Dispatch Standards, recommend the User prioritize that report.

### 2.5 Merge Standards

Merge state is a dispatch prerequisite. Merge completed feature branches into the base branch at specific coordination points.

**Merge timing:** After successful Task Review, merge the completed branch. Before dependent dispatch, merge if the dependent Task needs the completed Task's output. At Stage end, all current-Stage feature branches must be merged.

**Merge execution:** Clean merges require no User intervention. Perform merges autonomously - switch to the base branch (`git checkout <base-branch>`), merge the completed branch (`git merge <branch-name>`), then verify.

**Conflict resolution:** Resolve using coordination-level context - knowledge of both Tasks' objectives, project design, and the Spec. For complex conflicts, spawn a debug subagent or escalate to the User.

**Branch protection adaptation:** If the base branch has protection rules preventing direct merges, adapt (create a PR, merge into an intermediate branch, or ask the User). Discovered reactively and noted in working notes.

**Cleanup:** After a successful merge, clean up in order - first remove the worktree if one exists (`git worktree remove .apm/worktrees/<branch-slug>`), then delete the merged feature branch (`git branch -d <branch-name>`). The branch cannot be deleted while a worktree references it. During Stage-end merge sweeps with multiple branches, batch all removals first, then all deletions, in a single terminal invocation.

### 2.6 Stage Summary Standards

Stage summaries are the historical record of what happened during the Stage - written for future incoming Manager instances (after Handoff) and project retrospectives. They capture the Stage's coordination history and absorb Stage-specific observations from working notes during distillation. Write as descriptive prose covering outcome, agents involved, notable findings, patterns, and key decisions - point to commits where relevant. Implementation details belong in Task Logs, not here - but when working notes captured important events that involved implementation specifics, those are part of the Stage's history and belong in the summary. Follow with a Task Log reference list for deeper detail. Keep concise - coordination-ready context, not comprehensive documentation. Do not duplicate Memory notes as a separate section.

### 2.7 Note-Taking Standards

Notes capture context that falls outside structured tracking but aids coordination and continuity. Two categories serve different purposes:

**Working Notes (Tracker):** Coordination context accumulated during the Stage - pending considerations, User preferences, temporary constraints, technical observations, patterns noticed during reviews. Insert when a review yields note-worthy context. Remove items that are no longer applicable as the Stage progresses. At Stage end, all working notes are distilled into two destinations per §3.5 Stage Summary Creation (Stage summary prose per §2.6 Stage Summary Standards and Memory notes).

**Memory Notes (Index):** Observations with lasting impact on future Stages, coordination, or assignments - User preferences, operational principles, architectural insights, patterns that shape upcoming decisions. Not all working notes become Memory notes. Implementation details and Stage-specific observations belong in the Stage summary, not in Memory - they are historical, not forward-looking.

Use a bulleted list for both types - one item per note, each self-contained and understandable without surrounding context.

### 2.8 Stage Verification Standards

After all Tasks in a Stage are Done, assess whether the Stage's deliverables require holistic verification before writing the Stage summary and proceeding. This is a judgment call, not a mandatory step.

**When to verify:** Stages where the User confirmed verification during the understanding summary approval, where Task Reviews surfaced edge cases or compatibility concerns, where follow-up prompts were required during the Stage, where Workers reported difficulties or important findings, where the Planner flagged complexity in Plan notes, or where accumulated working notes suggest deliverables should be checked as a whole. Simple Stages with clean Task Reviews and no flags can proceed directly to the summary.

**How to verify:** Re-run the most important validation checks Workers already performed, exercise edge cases that individual Task validation may not have covered, run holistic end-to-end checks across the Stage's deliverables, and read source files, artifacts, or data to confirm the codebase is in the expected state. Verification should match the validation patterns established in the project - the same kinds of checks at the integration level. For context-intensive checks, dispatch a verification subagent and verify its findings against the referenced files before acting on them.

**When verification reveals issues:** Determine the appropriate response based on scope. For contained issues you can resolve directly, fix them. For issues requiring focused investigation, dispatch a subagent. For issues requiring Worker-level execution, create a new Task through Plan modification per §2.3 Planning Document Modification Standards. For issues whose scope or direction is unclear, present findings to the User with your assessment and proposed options. When verification requires User judgment or action, present findings and pause.

### 2.9 Non-APM Agent Reports

When a report arrives from an agent not listed in Worker tracking, it is a non-APM agent that joined the session independently. These reports do not follow the standard processing flow - there is no Task Log, no Worker tracking entry, and no dispatch state to update. Assess the report on its own terms: what the agent did, whether it affects planning documents or current dispatch. Add a working note to the Tracker recording the agent's identity and contribution. Inform the User of the findings. If follow-up work is needed, assign it per `{GUIDE_PATH:task-assignment}` §2.7 Non-APM Agent Dispatch.

### 2.10 Worker Queue Check Stop Standards

When Autonomous Mode is active, Workers enter Work Queue Check (§3.7) after Task Completion until work arrives or queue checking stops. When you review a Worker's report and that Worker has no further work to pick up, stop queue checking so the Worker session can end cleanly.

**Stop queue checking when ALL are true** (for each Worker whose report was processed in the current review cycle):
- No `Ready` Tasks assigned to that Worker in the Tracker (after reassessment)
- You are not writing a Task Prompt or follow-up to that Worker's Task Bus in this review-dispatch turn
- That Worker has no `Active` Task in the Tracker

**Do not stop when:**
- You dispatch or write a follow-up to that Worker in this turn (Task Bus will be populated)
- `Ready` Tasks remain assigned to that Worker (work exists — dispatch instead, or leave polling active until the Task Bus is populated)
- That Worker has an **`Active` Task** in the Tracker (assignment in flight — report not yet processed)
- That Worker's Task Bus (`.apm/bus/<agent-slug>/task.md`) is **non-empty** — assignment awaiting pickup; read the bus before stopping
- Another Worker's report was processed this cycle but **this** Worker is part of the same parallel dispatch unit and still has Active work or a populated Task Bus

**Before running stop script:** Read the Worker's Task Bus. If non-empty, **do not stop** — the Worker should pick up the assignment on the next poll cycle or via `{COMMAND_SLUG:task}` / `{COMMAND_SLUG:work}`.

**Execution:** Run via terminal:

```bash
bash .apm/scripts/stop-task-polling.sh <agent-slug>
```

Inform the User that Work Queue Check was stopped for that Worker because no further work is currently assigned. Update Worker tracking Notes (e.g., `queue check stopped after review — no Ready Tasks`). When work becomes Ready later, dispatch per `{GUIDE_PATH:task-assignment}` §3.3 — the Worker may need `{COMMAND_SLUG:work}` or `{COMMAND_SLUG:task}` if the session ended after the stop.

### 2.11 Manager Report Queue Check Stop Standards

When Autonomous Mode is active, Manager Report Queue Check (§3.8) is independent of Worker Work Queue Check (§3.7). Stop checking Report Buses when coordination no longer requires automatic detection.

**Stop Report Queue Check when ANY of these apply:**
- Operator initiates Manager Handoff
- Operator runs `bash .apm/scripts/stop-report-polling.sh` or explicitly stops polling in chat
- Session context threshold met per §2.12 Manager Session Context Assessment Standards
- All Stages complete and project completion summary presented
- After review cycle: no Active Workers in Tracker, no non-empty Report Buses, and all relevant Workers stopped per §2.10
- Malformed report or missing Task Log that requires operator resolution before continuing (per report scope)

**Do not stop Report Queue Check when:**
- Workers are still Active or have non-empty Report Buses
- Ready Tasks exist and dispatch will follow in the same turn
- Operator has not stopped and context threshold is not met — continue the agent-driven poll loop
- Workers are polling for tasks but reports have not arrived yet (wait state)

**Execution:** Operator stop via terminal:

```bash
bash .apm/scripts/stop-report-polling.sh
```

Set `report_polling_enabled` false when stopping. Emit §3.8.2 Autonomous Session End Message when stopping from an active Report Queue Check loop under Autonomous Mode. Inform the User how to resume: re-enable Autonomous Mode and re-engage coordination via `{COMMAND_SLUG:manage}`, or run `{COMMAND_SLUG:review}` as Manual Mode fallback.

### 2.12 Manager Session Context Assessment Standards

Before continuing report polling after a review-dispatch cycle or before starting a new review-dispatch cycle when multiple reports are queued — assess session context utilization. Do not assess mid-review during §3.1–§3.3 Task Review Procedure steps.

**Threshold:** ~75% of estimated session context capacity — best-effort, not exact token count.

Evaluate composite signals; no single signal is required:

| Signal | Threshold indicator |
|--------|---------------------|
| Reviews completed this session | ≥5 substantial Task Reviews with log reads and Tracker updates |
| Investigation load | Multiple subagent spawns for review investigations in session |
| Parallel coordination | Many Workers active, multiple merge/dispatch cycles in session |
| Conversation length | Very long session with many prior turns and tool calls |
| Cursor context indicator | UI shows high context usage (when visible) |
| Operator signals | Operator mentions context limits, compaction, or slowness |
| Post-handoff early session | Recently handed off — bias toward `low` unless rapid growth |

**Classification:**

| Result | Criteria | Action |
|--------|----------|--------|
| `below_threshold` | Estimate clearly under 75% | Continue Report Queue Check |
| `at_or_above_threshold` | Estimate ≥75% | Stop Report Queue Check; recommend Handoff |
| `uncertain_high` | Cannot estimate; risk of exceeding | Treat as `at_or_above_threshold` (conservative) |

When uncertain, favor Handoff recommendation (conservative default). Recompute before each poll-loop continuation after review-dispatch cycles — do not cache across long idle periods.

**When threshold met:**
1. Complete current review if in progress.
2. Do NOT begin additional review-dispatch cycles in the current session.
3. Inform the User: estimated context is high (~75% or uncertain); recommend Handoff via `{COMMAND_SLUG:handoff.manager}`; start new Manager via `{COMMAND_SLUG:manage}`; unprocessed reports remain on Report Buses.
4. Set `report_polling_enabled` false.
5. Run `bash .apm/scripts/stop-report-polling.sh` if poll loop is active.
6. Do NOT clear unprocessed Report Buses.
7. Emit §3.8.2 Autonomous Session End Message.

### 2.13 Execution Mode Detection

APM supports two execution modes: **Manual Mode** (default) and **Autonomous Mode** (opt-in paired polling). Detect mode at Manager session initiation and re-evaluate at Report Queue Check entry.

**Session attribute:** `autonomous_mode_enabled` — parent gate that determines whether §3.8 may run.

**Detection procedure:**

ON session init OR before entering §3.8 Report Queue Check:

1. Read project Cursor rule file `.cursor/rules/apm-autonomous.mdc`. If present and declares Autonomous Execution Mode active, set `autonomous_mode_enabled = true`. Otherwise set `autonomous_mode_enabled = false`.
2. When Manual Mode (`autonomous_mode_enabled` false): set `report_polling_enabled = false`. Do not enter §3.8 until Autonomous Mode is active and gates permit entry.
3. Inform the operator which Execution Mode is active (Manual or Autonomous) and what it implies for this Manager session.
4. For mode semantics, coupling invariants, mismatch fallback, and stop behavior, read `{SKILL_PATH:apm-autonomous}`.

**Re-evaluation:** If the operator may have enabled or disabled Autonomous Mode mid-session (rule added or removed), re-run this procedure at §3.8 entry before other gates.

### 2.14 Mode Coupling Check

Run at §3.8 entry when `autonomous_mode_enabled` is true (immediately after §2.13). Skip when Manual Mode — no paired loop required.

**Purpose:** Enforce that Manager report checking and Worker task polling operate as an inseparable pair per `{SKILL_PATH:apm-autonomous}` §4 and FR-012.

**Procedure:**

WHEN `autonomous_mode_enabled` is true:

1. Re-read `.cursor/rules/apm-autonomous.mdc`. If absent OR does not declare Autonomous Execution Mode active → **coupling_fail** (reason: `rule_not_active`).
2. Assess Worker participation: Read `.apm/tracker.md` Worker tracking and Task Tracking. For each Worker with an `Active` Task or dispatched assignment expected to report:
   - IF Worker is uninitialized in Tracker AND operator has not started that Worker session → **coupling_ok with wait_state_notice** — inform the operator which Worker(s) must run `{COMMAND_SLUG:work}` or `{COMMAND_SLUG:task}`; continue §3.8 (not a hard fail).
3. ELSE → **coupling_ok**.

**On coupling_fail:**

1. Announce (substantive — full message, not shortened per §2.4):
   ```
   Autonomous Mode requires both Manager and Worker participation.
   Falling back to Manual Mode for this session.
   ```
2. Set `autonomous_mode_enabled = false`, `report_polling_enabled = false`.
3. Emit §3.8.2 Autonomous Session End Message.
4. Instruct the operator to run `{COMMAND_SLUG:review}` when Worker reports are delivered.
5. **Do not** enter Report Queue Check. Stop (end turn).

**On coupling_ok (with or without wait_state_notice):** Continue §3.8 from step 0 Autonomous branch — set `report_polling_enabled = true` and proceed to step 1. When wait_state_notice applies, include expected Worker(s) in the operator message before starting the poll loop.

---

## 3. Task Review Procedure

Three sequential steps per report (processing, log review, outcome determination), with conditional branches for planning document modification and Stage summary creation. Update the Tracker after each cycle.

### 3.1 Report Processing

Execute when User runs `{COMMAND_SLUG:review}`, when Report Queue Check detects a report per §3.8, or when User returns with a Task Report (or batch report) from a Worker.

Perform the following actions:
1. Read the report from the Report Bus (`.apm/bus/<agent-slug>/report.md`).
2. If batch report (`batch: true` in frontmatter): the report contains per-Task outcomes in a `tasks` array (each with `stage`, `task`, `status`) and fields `completed`, `stopped_early`. Process each completed Task individually through §3.2 Task Log Review and §3.3 Review Outcome. Tasks with status `"Not started"` re-enter the dispatch pool.
3. Check for Handoff indication - look for a statement that the Worker is a new instance and a list of current-Stage Task Logs read. When previous Stages exist, the report also notes that previous-Stage logs were not loaded. If detected, verify the Handoff Log exists. Update Worker tracking in the Tracker: increment the instance number for this Worker. Compare the loaded Task Logs against all Tasks previously completed by this Worker and record cross-agent overrides in the Tracker for any completed Tasks whose logs were not loaded. From this point forward, previous-Stage same-agent dependencies for this Worker are treated as cross-agent.
4. Check for auto-compaction indication - a Worker that recovered from auto-compaction notes it in the Task Report. If detected, update Worker tracking Notes in the Tracker (e.g., "auto-compacted, recovered"). No dependency reclassification - the Worker continues as the same instance. Provide slightly more comprehensive dependency context in future Task Prompts for this Worker.
5. Update dispatch tracking: mark this Worker as available, note completed Task(s) for readiness assessment.
6. Merge completed branch per §2.5 Merge Standards if dependent Tasks need it.

### 3.2 Task Log Review

Execute after report processing. Present your assessment of the Task Log visibly in natural language: whether the claimed status is consistent with evidence, whether flags indicate coordination-relevant findings, and what the appropriate next action is.

Perform the following actions:
1. Read the Task Log at the path referenced in the Task Report.
2. Interpret content per §2.1 Task Log Review Standards: status, flags, body sections. Assess consistency between status/flags and body content.
3. Continue to the review outcome.

### 3.3 Review Outcome

Execute after Task Log review.

**Substantive content (Autonomous Mode):** Review assessments, investigation findings, and dispatch reasoning MUST follow full visible reasoning per `{SKILL_PATH:apm-communication}` §2.2 and §2.4 — concise feedback rules apply to wait-state repetition only, not to review outcome content. Do not shorten review assessments, stop guidance, or error diagnostics in the name of concise feedback.

Perform the following actions:
1. Review findings from the Task Log per §2.2 Review Outcome Standards. Assess deliverables against the Task's objectives and validation criteria before determining the outcome. If version control is active and the Task was successful but changes remain uncommitted on the Task branch, commit on behalf following the conventions from Rules - no follow-up needed. If everything looks good, skip to step 3. If something needs attention, continue to step 2.
2. Investigate and determine outcome per §2.2 Review Outcome Standards:
   - If no issues are found, continue to step 3.
   - If the Worker needs a follow-up, create a follow-up Task Prompt per `{GUIDE_PATH:task-assignment}` §3.4 Follow-Up Task Prompt Construction and continue to step 3.
   - If planning documents need modification, proceed to §3.4 Planning Document Modification (returns to step 3 after completion).
3. Update the Tracker per §4.1 Task Tracking Format: mark completed Tasks as Done, reassess Waiting Tasks for readiness, update branches. Execute pending merges per §2.5 Merge Standards before reassessing readiness. Assess whether the review yielded note-worthy context and add to working notes - both ephemeral coordination items and durable observations for later distillation. Remove stale working notes. Batch all changes from this review-dispatch cycle into a single Tracker edit.
4. Assess next action per §2.4 Parallel Coordination Standards:
   - If all Stage Tasks are Done and merged, collapse Stage per §4.1 Task Tracking Format and proceed to §3.5 Stage Summary Creation.
   - If Tasks are Ready, proceed to `{GUIDE_PATH:task-assignment}` §3.1 Dispatch Assessment in the same turn. Track which Workers receive a Task Prompt or follow-up in this turn.
   - If no Tasks are Ready but Workers are active, communicate wait state per §2.4 Parallel Coordination Standards and direct User to return the next report.
5. **Stop Worker polling** per §2.10 Worker Polling Stop Standards: for each Worker whose report was processed in this cycle, if that Worker received no dispatch this turn and has no Ready Tasks, run `bash .apm/scripts/stop-task-polling.sh <agent-slug>` and update Worker tracking Notes.

### 3.4 Planning Document Modification

Execute when the review outcome identifies that planning documents need modification. Always triggered from §3.3 Review Outcome.

Perform the following actions:
1. Capture triggering context: which Task Log revealed the findings, what specific findings indicate modification, Task status and flags, post-investigation outcome.
2. Apply §2.3 Planning Document Modification Standards: assess affected documents, analyze cascade implications, determine authority scope.
3. If any modification is significant enough to require User input, present concisely: what triggered it, what needs to change, why it exceeds what you can decide alone, options with trade-offs, and your recommendation. Integrate User guidance.
4. Execute modifications following existing document patterns per §4.5 Planning Document Modification Guidelines. Verify consistency: reference integrity across documents (same data descriptions match), terminology consistency, scope alignment between the Spec and Plan. When correcting the Spec, check whether the Plan references the same content and update accordingly.
5. When modifying Plan Tasks (adding, removing, or changing dependencies), update the Dependency Graph per §4.5 Planning Document Modification Guidelines.
6. Document: update `modified` field in Spec and/or Plan YAML frontmatter per §4.4 Modification Log Format.
7. Proceed to §3.3 Review Outcome step 4 to update tracking. Reassess readiness against the updated Plan and proceed accordingly.

### 3.5 Stage Summary Creation

Execute when all Tasks in a Stage are Done. A Task is Done when the review concludes with no outstanding follow-ups. Write the Stage summary once, after all follow-up cycles finish.

Perform the following actions:
1. Enumerate Task Logs for the completed Stage using a directory listing, e.g., `ls .apm/memory/stage-<NN>/` (or platform equivalent). Synthesize from logs already reviewed during individual Task Reviews - re-reading is not needed when logs are unchanged and still in context.
2. Assess whether Stage verification is needed per §2.8 Stage Verification Standards. When warranted, verify before proceeding.
3. Distill working notes per §2.7 Note-Taking Standards: observations with lasting impact on future work become Memory notes in the Index, Stage-specific observations become Stage summary prose. Keep working notes that will be needed in the next Stage. When this review immediately triggers Stage summary (last Task in Stage), observations from this review can be written directly to their destinations rather than first passing through working notes.
4. Synthesize Stage-level observations and append a Stage summary to the Index per §4.3 Index Format. The Index structure (Memory notes above Stage summaries) enables steps 3 and 4 as a single contiguous edit.

### 3.8 Report Queue Check Procedure

After a dispatch cycle completes, automatically check Report Buses for Worker Task Reports when Autonomous Mode gates permit entry. When reports arrive, process them per §3 Task Review Procedure, dispatch follow-on Tasks or stop Worker polling, and resume checking until stop conditions apply — all in the same coordination turn when possible.

**Loop structure (FR-007, SC-006):** Step 0 (Autonomous Mode gate and §2.14 mode coupling check) runs **once** when entering §3.8 from `{COMMAND_PATH:apm.manage}` §3 Continuous Coordination or explicit Manager re-entry into report polling. The **review-dispatch-resume loop** (steps 1 → 3 → 4 → 5 → 6 → 1) does **not** re-run step 0 — preserving feature 002 parallel report handling and same-turn reassessment per §2.4 Parallel Coordination Standards. Re-run step 0 only when starting a **new** §3.8 entry after the procedure fully exits (end turn).

**Parallel multi-Worker (unchanged from 002):** Reports may arrive in any order from multiple Workers. Process each report through §3.1–§3.3 per §2.4 Async report handling. When `poll-report-bus.sh` discovers multiple non-empty Report Buses, batch-read and process all in the current cycle before reassessing dispatch. Parallel dispatch to multiple Workers in step 6 follows `{GUIDE_PATH:task-assignment}` §2.4 and §3.3 — Autonomous Mode gates do not serialize cross-Worker coordination.

**Poll-until-stop (FR-017):** An empty Report Bus is **not** a stop condition. When the poll script returns `STILL_EMPTY`, re-invoke the poll script immediately in the same conversation turn — the script sleeps internally between checks. **Do not** run a separate `sleep` command. **Do not** end the turn after a single empty check, idle announcement, or because Cursor aborted a long-running shell command — re-invoke the poll script until `REPORT_FOUND`, `POLLING_STOPPED`, or a stop condition in §3.8.1 fires.

**Session attributes** (maintain during the session):
- `report_polling_enabled`: Whether automatic Report Bus checking is active. **Manual Mode default: false** at session init (§2.13). **Autonomous Mode default: true** after §3.8 step 0 gate permits entry (typically after first dispatch). Set false when operator stops, Handoff initiates, context threshold triggers, coordination completes, or Manual Mode is detected.
- `reviews_completed_this_session`: Count of substantial Task Reviews completed this session (increment after each §3 review cycle)
- `context_estimate`: Best-effort utilization (`low` / `moderate` / `high` / `threshold` / `uncertain`)
- **Poll stretch (Autonomous Mode only, per `{SKILL_PATH:apm-communication}` §2.4):** `empty_poll_count`, `wait_state_sent`, `last_wait_state_at` — track wait-state suppression during consecutive `STILL_EMPTY` results. Initialize on poll loop entry; reset on `REPORT_FOUND`, dispatch, or stop.

**Scripts** (project root, shipped in `.apm/scripts/`):
- Poll: `bash .apm/scripts/poll-report-bus.sh` — internal check/sleep loop until `REPORT_FOUND`, `POLLING_STOPPED`, or chunk timeout (`STILL_EMPTY`)
- Stop button: `bash .apm/scripts/stop-report-polling.sh`

**Polling model:** The poll script loops internally (check → sleep → check) for up to `${APM_POLL_CHUNK_SECONDS:-50}` seconds per invocation. The Manager re-invokes the script on `STILL_EMPTY` in a **same-turn agent loop** — one shell tool call per chunk, not per internal check. Cursor aborts shell commands longer than ~60 seconds; chunk default stays under that limit. **Do not** run a separate `sleep` between invocations. Giving up after a few `STILL_EMPTY` chunks is a procedure violation.

Perform the following actions:

0. **Autonomous Mode gate (entry only):** Run §2.13 Execution Mode Detection. Then:
   - **IF** `autonomous_mode_enabled` is false (**Manual Mode**): Instruct the operator to run `{COMMAND_SLUG:review}` when Worker reports are delivered. Set `report_polling_enabled = false`. **Do not** enter Report Queue Check. **Do not** apply `{SKILL_PATH:apm-communication}` §2.4 wait-state suppression or compact heartbeat formats. Stop (end turn).
   - **IF** `autonomous_mode_enabled` is true (**Autonomous Mode**): Run §2.14 Mode Coupling Check. On **coupling_fail**, §2.14 handles Manual fallback and stop. On **coupling_ok**, set `report_polling_enabled = true` and continue to step 1.

   *This step runs once per §3.8 entry — not on step 6 loop-back.*

1. **Polling gate:** If `report_polling_enabled` is false, announce that Report Queue Check (§3.8) is stopped. If queue checking was previously active this session under Autonomous Mode, emit §3.8.2 Autonomous Session End Message. Await explicit operator instruction to resume (`{COMMAND_SLUG:review}` or next dispatch cycle). Stop (end turn).

2. **Stop condition evaluation:** Evaluate stop conditions per §3.8.1 before polling (except operator stop via stop script, handled during poll). If Handoff is initiated, follow `{COMMAND_PATH:apm.handoff.manager}`, set `report_polling_enabled` false, emit §3.8.2 Autonomous Session End Message, and stop. If operator explicitly stops in chat ("stop", "wait", "pause polling", or equivalent), set `report_polling_enabled` false, run `bash .apm/scripts/stop-report-polling.sh` if poll loop is active, emit §3.8.2 Autonomous Session End Message, confirm stopped state, and stop (end turn).

3. **Start polling loop (agent-driven):** Verify `.apm/scripts/poll-report-bus.sh` exists. If missing, inform the operator that APM must be updated (`apm update` or project-equivalent) to install polling scripts — do not end turn awaiting `{COMMAND_SLUG:review}`.

   **Init-before-poll gate:** If this §3.8 entry follows dispatch and any dispatched Worker requires init, **confirm** dispatch summary and per-Worker fenced `{COMMAND_SLUG:work}` copy blocks are already in chat per `{SKILL_PATH:apm-communication}` §2.4. If not, emit them **now** before step 3a. **Do not** invoke `poll-report-bus.sh` until copy blocks are present.

   **Stale stop (session entry):** If `clear-stale-polling-stop.sh manager` was not run this session (operator resumed mid-procedure), run it now before step 3a — same rules as `{COMMAND_PATH:apm.manage}` §2 step 3.

   **End-of-turn gate (FR-017):** While `report_polling_enabled` is true, ending the conversation turn is **prohibited** unless one of these applies:
   - Poll loop exited via `POLLING_STOPPED` and §3.8.2 was emitted
   - A §3.8.1 stop condition was handled per procedure (including coordination complete)
   - You are continuing the same turn between step 3a shell output and the next step 3a re-invocation (or step 4–6 review-dispatch-resume)
   - Step 4–6 review-dispatch-resume is in progress in the same turn

   **Pre-send self-check (mandatory before final assistant message):** If `autonomous_mode_enabled` is true AND `report_polling_enabled` is true AND no §3.8.1 stop condition was handled this cycle:
   - Confirm `poll-report-bus.sh` ran via shell **after** the most recent dispatch in **this turn**
   - **IF** the last poll output was `STILL_EMPTY` → invoke step 3a again; **do not** send the final message yet
   - **IF** the draft message tells the operator to run `{COMMAND_SLUG:manage}`, `{COMMAND_SLUG:review}`, or "say resume" to process reports → delete that instruction and continue polling instead
   - **IF** the draft message says "checking for reports" or similar without a poll invocation after it in this turn → run step 3a before sending

   Announcing "Report Queue Check is active", "I'll process when the report arrives", or similar **does not** satisfy this gate. You must run the shell poll loop.

   **Operator init then poll (same turn):** When this §3.8 entry follows a dispatch that wrote Task Prompts to Workers not actively polling, emit **separate per-Worker init copy blocks** per `{SKILL_PATH:apm-communication}` §2.4, then **immediately** run step 3a in this turn. Init blocks do **not** pause coordination — the Manager polls while the operator opens Worker chats. **Do not end the turn** between init blocks and step 3a.

   **First poll mandatory — loop until stop:** After init blocks (when required), run step 3a at least once in this turn before ending. **`STILL_EMPTY` requires immediate re-invocation of step 3a** — one chunk (~50s) is not a valid exit. If output is `REPORT_FOUND`, proceed immediately to step 4 — do not instruct the operator to run `{COMMAND_SLUG:review}`.

   When Autonomous Mode is active, display the stop command — **after** the first step 3a invocation, or interleaved with the poll loop, not instead of it. Apply wait-state suppression per `{SKILL_PATH:apm-communication}` §2.4 on `STILL_EMPTY` — do not announce Report Queue Check on every empty cycle:

   ```bash
   bash .apm/scripts/stop-report-polling.sh
   ```

   **On poll loop entry (Autonomous Mode):** Initialize poll stretch attributes: `empty_poll_count = 0`, `wait_state_sent = false`, `last_wait_state_at = null`.

   **Repeat** the following until `REPORT_FOUND` or `POLLING_STOPPED` — do not end the turn, do not abort after a time limit or number of empty checks, and do not tell the operator to run `{COMMAND_SLUG:review}` again to resume polling. **`STILL_EMPTY` is not a stop signal** — re-invoke step 3a immediately (script slept internally). **Do not** use a bash `for`/`while` loop wrapping multiple poll calls in one shell command — branch on stdout after each step 3a invocation. **Do not** run a separate `sleep` between invocations.

   a. Run via shell tool:

   ```bash
   bash .apm/scripts/poll-report-bus.sh
   ```

   b. Branch on output:
   - **`REPORT_FOUND`:** Reset poll stretch attributes (`empty_poll_count`, `wait_state_sent`, `last_wait_state_at`). Emit **state-change** message per `{SKILL_PATH:apm-communication}` §2.4 (e.g., `Report received from {worker-slug} (Task {id})`) before review processing. Exit this loop; continue to step 4.
   - **`POLLING_STOPPED`:** Set `report_polling_enabled` false. Confirm polling was stopped via the stop button (stop file consumed on this check). Emit §3.8.2 Autonomous Session End Message. State how to resume (re-enable Autonomous Mode and re-engage `{COMMAND_SLUG:manage}`, or use `{COMMAND_SLUG:review}` in Manual Mode). **Stop (end turn)** — do not return to step 3a or resume polling because the operator asked to continue in chat. **Exception:** If `clear-stale-polling-stop.sh manager` was **not** run this session and the operator did not run the stop script this session, run clear-stale once and return to step 3a — leftover stop files from prior sessions do not apply.
   - **`STILL_EMPTY`:** Apply wait-state suppression per `{SKILL_PATH:apm-communication}` §2.4:
     1. Increment `empty_poll_count`.
     2. **IF** `wait_state_sent` is false: emit initial wait-state (`Manager: checking for reports…`); set `wait_state_sent = true`; record `last_wait_state_at`.
     3. **ELSE IF** quiet interval elapsed (`empty_poll_count >= ${APM_POLL_QUIET_CYCLES:-5}` OR elapsed ≥ `${APM_POLL_QUIET_SECONDS:-60}` since `last_wait_state_at`): emit refresh wait-state (optional elapsed hint); reset `empty_poll_count` to 0; update `last_wait_state_at`.
     4. **ELSE:** Suppress chat output for this cycle.
     5. **Always:** Return to step 3a immediately — do not skip poll script because chat was suppressed; do not run a separate `sleep` command:

4. **Process reports (parallel-safe):** For each non-empty Report Bus discovered — when multiple Workers report, batch-read all in a single terminal invocation — read report content. Process reports in discovery order; arrival order does not affect Tracker correctness per §2.4 Async report handling. If the agent is not in Worker tracking, process per §2.9 Non-APM Agent Reports. Otherwise, process **each** report through §3.1 Report Processing, §3.2 Task Log Review, and §3.3 Review Outcome before reassessing dispatch for the cycle. If a Task Log is missing or report content is unparseable, surface the error, do not mark the Task Done, and handle per §3.8.1 Priority 7. Clear each processed Report Bus after processing per bus protocol. Increment `reviews_completed_this_session` after each substantial review cycle.

5. **Context threshold assessment:** Assess session context utilization per §2.12 Manager Session Context Assessment Standards. If threshold is met or uncertain-high, handle per §2.12 and stop (end turn) — preserve unprocessed Report Buses.

6. **Review-dispatch-resume loop (parallel-safe):** After processing all reports in this cycle per §2.4 Parallel Coordination Standards — immediate reassessment, merge before dependent dispatch, same-turn review-to-dispatch:
   - If Ready Tasks exist, run dispatch assessment and Task Prompt construction per `{GUIDE_PATH:task-assignment}` §3.1–§3.3 (including parallel dispatch units when applicable). After dispatch writes complete, emit **dispatch summary** state-change per `{SKILL_PATH:apm-communication}` §2.4. When any dispatched Worker is uninitialized or not actively polling, emit **separate per-Worker init copy blocks** per §2.4, then **immediately** continue to step 1 polling — same turn, no stop. **Return to step 1** — not step 0 — without ending the turn.
   - For each Worker whose report was processed this cycle with no Ready Tasks and no dispatch this turn, run `bash .apm/scripts/stop-task-polling.sh <agent-slug>` per §2.10 Worker Polling Stop Standards. **Do not** stop Workers who received dispatch this turn (Task Bus populated; polling continues). Inform the User that Worker polling was stopped and that the Worker may need `{COMMAND_SLUG:work}` or `{COMMAND_SLUG:task}` when work becomes Ready later.
   - If all Stage Tasks are Done and merged, proceed to §3.5 Stage Summary Creation as applicable, then continue assessment.
   - If no Active Workers remain in Tracker, no non-empty Report Buses exist, and all relevant Workers are stopped: set `report_polling_enabled` false, emit §3.8.2 Autonomous Session End Message, inform the User that coordination report polling has ended, and stop (end turn).
   - If Workers are still active or reports may still arrive, **return to step 1** — not step 0 — without ending the turn.

#### 3.8.1 Stop Conditions

Evaluate in priority order when multiple conditions may apply:

| Priority | Condition | Action |
|----------|-----------|--------|
| 1 | Operator initiates Manager Handoff | Follow `{COMMAND_PATH:apm.handoff.manager}`; preserve unprocessed Report Buses |
| 2 | Operator stop (stop button) | Poll script exits `POLLING_STOPPED`; set `report_polling_enabled` false |
| 3 | Operator explicit stop (in chat) | Set `report_polling_enabled` false; run stop script if poll active |
| 4 | Context threshold met | Handle per §2.12; preserve unprocessed Report Buses |
| 5 | Coordination complete | Project completion summary; no report polling after completion |
| 6 | No active Workers, no pending reports | Automatic stop after reassessment post-review |
| 7 | Malformed report / missing Task Log | Surface error; do not mark Done; operator resolves |

When stopping due to context threshold or Handoff with unprocessed reports, do NOT clear Report Buses for unprocessed reports.

#### 3.8.2 Autonomous Session End Message (FR-010)

When exiting an active autonomous Report Queue Check loop — stop script, operator explicit stop, Handoff, context threshold, coordination complete, coupling fail from autonomous state, or any §3.8.1 stop while autonomous polling was active this session — emit before ending the turn. This is **substantive** content per `{SKILL_PATH:apm-communication}` §2.4 — emit fully and unchanged; do not shorten for concise feedback:

```
Autonomous session has ended.
You may:
- Re-enable Autonomous Mode (ensure apm-autonomous rule is active, then continue with /apm.manage or /apm.work)
- Switch to manual coordination (/apm.review, /apm.task, /apm.work)
```

Preserve unprocessed Report Bus content, queued Task Bus assignments, and Tracker state. Do not auto-re-enter §3.8 until the operator re-enables Autonomous Mode and re-engages coordination.

---

## 4. Structural Specifications

### 4.1 Task Tracking Format

The Task Tracking section within the Tracker tracks Task statuses, agent assignments, and branch state per Stage. Update after each review cycle.

**Location:** `## Task Tracking` section of `.apm/tracker.md`.

**Format:**
```markdown
**Stage 1:** Complete

**Stage 2:**

| Task | Status | Agent | Branch |
|------|--------|-------|--------|
| 2.1 | Done | frontend-agent | |
| 2.2 | Active | backend-agent | feat/backend-models |
| 2.3 | Active | frontend-agent | feat/frontend-auth |
| 2.4 | Waiting: 2.1 | backend-agent | |
| 2.5 | Ready | frontend-agent | |
```

**Task statuses:** `Ready`, `Active`, `Done`, `Waiting: <deps>`.

**Task lifecycle:**
- `Waiting: N.M` - dependencies not met. May list multiple dependencies.
- `Ready` - all dependencies complete, can be dispatched.
- `Active | branch-name` - dispatched, Worker is on a branch.
- `Done | branch-name` - reviewed, branch pending merge.
- `Done` (no branch) - merged.

Write the end state of each Task for the review-dispatch cycle. When a Task is unblocked and dispatched in the same turn, write directly from Waiting to Active. When a Task is unblocked but cannot be dispatched - the assigned Worker has an Active Task or a pending report would unlock a better dispatch per `{GUIDE_PATH:task-assignment}` §2.4 Dispatch Standards - write Ready.

**Branch cleanup:** After merging a completed branch per §2.5 Merge Standards, clear the Branch column for that Task row.

**Stage collapse:** When all Tasks in a Stage are Done with no branches remaining, replace all Task rows with `**Stage N:** Complete`.

**Batch edits:** Task ID column guarantees edit tool uniqueness for targeting individual rows. When multiple rows or working notes change in the same review-dispatch cycle, batch all Tracker updates into a single edit.

### 4.2 Tracker Format

**Location:** `.apm/tracker.md`

**YAML Frontmatter Schema:**
```yaml
---
title: <project name>
completed_at: <datetime>  # set by Manager at project completion - absence means in-progress, ISO 8601 UTC
---
```

**Tracker sections:**
- *`## Task Tracking`:* Per-Stage Task state per §4.1 Task Tracking Format.
- *`## Worker Tracking`:* Records Worker states, instance numbers, and coordination notes. Update Worker tracking when Workers are first dispatched to, when Handoffs are detected, and when auto-compaction recovery is reported. Cross-agent overrides are recorded below the Worker table when Worker Handoffs reclassify dependencies, listing the specific Tasks affected and referencing the Handoff that triggered the reclassification.
- *`## Version Control`:* Per-repository base branch, branch convention, and commit convention per `{GUIDE_PATH:task-assignment}` §4.4 Tracker VC Entry Format. Branch state is tracked per-Task in the Task table's Branch column.
- *`## Working Notes`:* Ephemeral coordination context per §2.7 Note-Taking Standards. Contents are inserted and removed as context evolves.

**Worker Tracking Table:**
```markdown
| Agent | Instance | Notes |
|-------|----------|-------|
| frontend-agent | 2 | Handoff after Stage 1 |
| backend-agent | 1 | |
```

**Cross-Agent Overrides** (below Worker Tracking table, when applicable):
```markdown
**Cross-Agent Overrides:**
- frontend-agent: Tasks 1.1, 1.3 (pre-Handoff) - treat as cross-agent
```

### 4.3 Index Format

**Location:** `.apm/memory/index.md`

**YAML Frontmatter Schema:**
```yaml
---
title: <project name>
---
```

**Index sections:**
- *`## Memory Notes`:* Durable observations per §2.7 Note-Taking Standards. Patterns, preferences, and insights that persist across Handoffs.
- *`## Stage Summaries`:* Appended after each Stage completion. Each entry:
```markdown
### Stage <N> - <Stage Name>

[Prose summary: outcome, agents involved, notable findings, patterns, key commits]

**Task Logs:**
- task-<NN>-<MM>.log.md
- task-<NN>-<MM>.log.md
```

### 4.4 Modification Log Format

Update the `modified` field in YAML frontmatter when modifying the Spec or Plan:
```yaml
modified: Task 2.3 scope clarified based on task-02-02.log.md findings. Modified by the Manager.
```

### 4.5 Planning Document Modification Guidelines

**Spec:** Maintain existing section structure. Add content under relevant headings. Use `##` for top-level categories. Keep specifications concrete and actionable - design decisions that affect what is being built and apply across multiple Tasks. Task-specific details belong in Task guidance, not here.

**Plan:**
- *Adding Tasks:* Insert under the appropriate Stage, maintain numbering sequence, specify all fields (Objective, Output, Validation, Guidance, Dependencies, Steps).
- *Modifying Tasks:* Preserve existing structure, update only affected fields.
- *Removing Tasks:* Delete the Task section AND update any other Tasks that referenced it as a dependency.

**Rules:** Modifications stay within the `APM_RULES {}` block. Use `##` headings for categories. Only add genuinely universal patterns.

**Dependency Graph:** When Task dependencies change, regenerate the relevant graph section. Same-agent dependencies use `-->`, cross-agent use `-.->`. Update node styles if agents change.

---

## 5. Common Mistakes

- *Status inconsistency:* When a Worker claims Success but the log body shows incomplete validation, unresolved issues, or missing deliverables, treat the content as authoritative over the status field and investigate before accepting.
- *Accepting insufficient reports:* Marking Tasks as Done when validation criteria were not fully exercised or deliverables are partial. Push back with a follow-up Task Prompt before accepting.
- *Skipping Handoff detection:* Failing to track Worker Handoff leads to incorrect dependency context treatment.
- *Unacknowledged recovery:* When a Worker report indicates auto-compaction occurred, factor this into the assessment - reconstructed context may have affected report completeness.
- *Single-document tunnel vision:* Updating the Spec without checking whether the Plan references the same content, or modifying the Plan without assessing whether the Spec's design assumptions still hold. Changes to one planning document often cascade to the other.
- *Symptom treatment:* Modifying one document to work around an issue that should be addressed in another. When an issue surfaces in execution, trace it to the document where the root cause lives rather than patching around it elsewhere.
- *Ending turn on empty report bus:* After dispatch, ending the turn after a single `STILL_EMPTY` from `poll-report-bus.sh`, announcing that no reports are available, or waiting for the operator to run `{COMMAND_SLUG:review}` again while `report_polling_enabled` remains true. Report Queue Check requires re-invoking the poll script on `STILL_EMPTY` until `REPORT_FOUND`, `POLLING_STOPPED`, or a §3.8.1 stop condition. An empty Report Bus alone is never a valid reason to end the turn while polling is active.
- *Separate sleep between poll invocations:* Running `sleep ${APM_POLL_INTERVAL:-10}` as its own shell call after `STILL_EMPTY`. Sleep is internal to the poll script; re-invoke immediately.
- *Bash for/while poll loops in agent shell:* Same prohibition as Worker §3.7 — the poll script loops internally; the agent re-invokes on `STILL_EMPTY`.
- *Continuing after `POLLING_STOPPED`:* When `poll-report-bus.sh` returns `POLLING_STOPPED`, stop immediately — do not resume step 3a because the operator asked to "continue polling" in chat. **Exception:** leftover stop file from a prior session — run `clear-stale-polling-stop.sh manager` at `{COMMAND_SLUG:manage}` entry (§2 step 3); if missed, run once and retry step 3a before §3.8.2.
- *Stale stop treated as session end:* Emitting §3.8.2 on first poll because `report-polling.stop` existed from a prior session without running `clear-stale-polling-stop.sh manager` at session entry.
- *Announcing polling without executing:* Stating "Report Queue Check is active" or "I'll process the report when it arrives" without running `bash .apm/scripts/poll-report-bus.sh` via the shell tool in the same turn. Textual commitment to poll is not polling — the §3.8 end-of-turn gate requires at least one shell poll invocation before ending while `report_polling_enabled` is true.
- *Instructing manual review while autonomous:* Telling the operator to run `{COMMAND_SLUG:review}` after dispatch or while `report_polling_enabled` is true and Autonomous Mode is active. That is Manual Mode (FR-003); run the §3.8 poll loop instead. `{COMMAND_SLUG:review}` is fallback only after polling stops or Autonomous Mode ends.
- *Aborting report polling early:* Ending the turn after a few empty checks or because Cursor aborted a long-running shell command. Use repeated short shell calls — not one long-running bash process.
- *Wait-state every empty cycle:* Emitting a status line on every `STILL_EMPTY` instead of applying §2.4 suppression. During ≥10 empty polls, at most 2 wait-state lines (initial + optional refresh).
- *Chat instead of polling:* Announcing report checking without running `poll-report-bus.sh` via shell, or suppressing chat and skipping the poll script. Suppression affects operator output only — shell polling continues regardless.
- *Shortened review/stop/error messages:* Truncating review assessments, §3.8.2 session-end, coupling fallback, or malformed report diagnostics for brevity. Substantive messages remain fully explicit per `{SKILL_PATH:apm-communication}` §2.2 and §2.4.
- *Omitting Worker init (single or parallel):* Dispatching without separate per-Worker fenced `{COMMAND_SLUG:work}` blocks when init is required — includes first dispatch to a **single** Worker at Stage start.
- *Omitting parallel Worker init:* Dispatching to multiple Workers without separate per-Worker fenced `{COMMAND_SLUG:work}` blocks for each Worker that is not actively polling.
- *Init narration without copy blocks:* Writing "Workers need initialization" without per-Worker fenced commands.
- *Stopping after init:* Ending the turn after init copy blocks without immediately running `poll-report-bus.sh` in the same turn, or telling the operator to run `{COMMAND_SLUG:manage}` again to start polling.
- *Combined init fence:* Listing all Workers in one code fence instead of separate fences per Worker.
- *Poll before init blocks:* Running `poll-report-bus.sh` before emitting per-Worker Operator Worker Init when any dispatched Worker requires init.
- *Polling boilerplate every turn:* Repeating execution-mode recap, "Report Queue Check is active", or stop-script blocks on every review-dispatch cycle while polling continues — use §2.4 wait-state suppression and show stop command once per poll-loop entry.
- *Banned re-run instructions (Autonomous Mode):* Telling the operator any of the following while `report_polling_enabled` is true and Workers are active — run §3.8 poll loop or `{COMMAND_PATH:apm.manage}` §2.3 Operator Resume instead:
  - "Run `{COMMAND_SLUG:manage}` again" (or "re-run `{COMMAND_SLUG:manage}`") to start or resume report polling
  - "Run `{COMMAND_SLUG:manage}` again (or say resume)" to process reports
  - "leave this session polling" — the turn ends when you stop; polling does not continue in the background
  - "once the Worker finishes" / "when the Integration Agent completes" without an active `poll-report-bus.sh` loop in this turn
  - "I'll process the report when it arrives" without immediately running step 3a
- *Resume as status-only:* When the operator says `resume` or `continue`, ending the turn after a status table without re-entering §3.8 — treat as Operator Resume per `{COMMAND_PATH:apm.manage}` §2.3.

---

**End of Guide**
