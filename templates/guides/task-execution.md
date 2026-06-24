# APM {VERSION} - Task Execution Guide

## 1. Overview

**Reading Agent:** Worker

This guide defines how you execute Tasks assigned by the Manager via Task Prompts, from receipt through context integration, execution, validation, iteration, and completion.

---

## 2. Operational Standards

Write clean, maintainable code following best practices for the language and framework in use. Use descriptive naming and add comments where the logic is not self-evident. Follow the existing codebase's patterns, conventions, and structure. Build incrementally - validate after each meaningful step rather than producing everything at once. These are baseline defaults; Task Prompt instructions and Rules take precedence when they specify otherwise.

### 2.1 Context Integration Standards

Follow cross-agent integration steps completely - read files, review artifacts, understand interfaces. For dependency integration that requires reading specific files at known paths, read them directly. Subagent dispatch is for open-ended exploration or investigation where the scope is broad or context isolation is beneficial. Use same-agent guidance as recall anchors - review referenced paths to refresh context if needed.

**Integration issues:** Do not execute on an unstable foundation. For cross-agent dependencies, pause for User guidance. For same-agent, minor ambiguities - continue with best interpretation and note uncertainty; missing expected files - pause for guidance.

### 2.2 Validation Standards

Validation criteria in the Task Prompt specify what to check. Execute each criterion as written - run tests, verify outputs exist and match expected structure, confirm behavior meets requirements. Always complete autonomous checks first. If any autonomous check fails, correct it before involving the User - do not request User review or User action while autonomous checks are failing.

When a criterion requires User involvement - judgment the Worker cannot self-assess (design approval, content quality) or action outside the development environment (running external checks, confirming platform behavior) - pause and present work only after all autonomous checks pass. When pausing, communicate clearly per `{SKILL_PATH:apm-communication}` §2.1 Direct Communication: what is needed and why, what the User should expect or verify, and what to report back so execution can continue.

When criteria require resources not currently available, request them from the User rather than substituting a lower verification level.

### 2.3 Iteration Standards

When validation fails, you enter a correction loop - investigate, correct, re-validate.

**Investigate before fixing.** Read error output thoroughly, trace the failure to its origin, and understand what specifically went wrong before changing anything. Attempting fixes without understanding the cause compounds problems and wastes iterations.

**One targeted fix per iteration.** Apply a single change based on what your investigation found, then re-validate. When a correction does not resolve the issue - the same failure recurs, the fix introduces new problems, or the root cause remains unclear - spawn a debug subagent with structured instructions: the error output, what you investigated and attempted, relevant file paths, and the expected vs actual behavior. Direct it to trace the root cause, form a specific hypothesis, and propose a targeted fix. The subagent iterates in a fresh context while your main context is preserved for validating its findings. When the root cause could stem from multiple independent areas, spawn separate subagents in parallel. When a subagent returns, validate its findings before applying - confirm the root cause explanation makes sense and the fix addresses it. If unresolved after subagent investigation, prefer reporting back with Partial status - the Manager can restructure or reassign. When execution suggests Task Prompt instructions may be inaccurate, this is also a reason to stop iterating. When classification is unclear, prefer Partial with clear description - invites guidance rather than closing options.

**User collaboration:** Pause when criteria require User judgment (you cannot self-approve subjective quality), when explicit User actions are needed (outside the development environment), when environment resources are needed for validation, or when iteration stalls and you need guidance. Continue autonomously when checks can be performed without User involvement and when the cause of failure is clear and the fix is within scope. When uncertain or stopping without Success, pause and present the situation to the User with options rather than making unilateral decisions.

### 2.4 Rules Updates

When the User provides a correction or directive during execution, comply immediately and continue. Do not pause to discuss Rules at this point. At Task completion, note the correction in the Task Log under Important Findings with `important_findings: true` - the Manager will see it during Task Review regardless of what happens next. After logging, reporting, and directing the User to deliver the report, ask at the end of your turn whether the correction should become a Rule for all Workers - frame it naturally based on what was said and why it might apply beyond this Task. Make it clear the User can ignore this and proceed with delivering the report - it is not a gate. If the User approves, update `{RULES_FILE}` and update the Task Log to note that the correction was entered as a Rule. If the User declines, defers, or ignores, no further action - the Manager already has visibility through the important findings flag.

### 2.5 Version Control Standards

Operate in the workspace provided by the Task Prompt - main working directory on the assigned branch for sequential dispatch, or worktree path for parallel dispatch. Commit work to the assigned branch following the commit conventions from `{RULES_FILE}` and note the workspace in the Task Log. You only commit - do not create branches, manage worktrees, push, or merge. The Manager handles all other version control operations. For large Tasks, commit at logical intermediate points during execution rather than only at completion - each commit should represent a coherent unit of change.

**Commit content:** APM terminology - Task IDs, Stage numbers, agent identifiers, framework vocabulary - does not appear in commit messages, branch references, or source code comments. Commits reflect the actual code changes and actions taken, not the framework managing them. Write commit messages as if no project management framework existed.

### 2.6 Batch Rules

When receiving a batch of Tasks (multiple Task Prompts in a single Task Bus message), execute sequentially. Complete each Task fully - execute, validate, and write the Task Log - before starting the next Task in the batch. Each Task gets its own Task Log at its specified `log_path`.

**Fail-fast:** If any Task results in Failed status, stop the batch. Do not proceed to remaining Tasks. After completing all Tasks (or stopping on failure), write a single batch report to the Report Bus per `{GUIDE_PATH:task-logging}` §4.3 Batch Report Format. Do not defer logging to the end of the batch.

### 2.7 Session Context Assessment Standards

Before every auto-pick attempt — continuing same-turn exhaustion after prior completion or when the poll script returns `WORK_FOUND` — assess session context utilization. Do not assess mid-assignment during §3.3–§3.5 execution; assess only at Work Queue Check boundaries (§3.7).

**Threshold:** ~75% of estimated session context capacity — best-effort, not exact token count.

Evaluate composite signals; no single signal is required:

| Signal | Threshold indicator |
|--------|---------------------|
| Assignments completed this session | ≥3 substantial Tasks with significant file reads/tool use |
| Correction loops | Multiple debug subagent spawns or extended iteration in session |
| Conversation length | Very long session with many prior turns and tool calls |
| Cursor context indicator | UI shows high context usage (when visible to operator/agent) |
| Operator signals | Operator mentions context limits, compaction, or slowness |
| Post-handoff early session | Recently handed off — bias toward `low` unless rapid growth |

**Classification:**

| Result | Criteria | Action |
|--------|----------|--------|
| `below_threshold` | Estimate clearly under 75% | Proceed with auto-pick |
| `at_or_above_threshold` | Estimate ≥75% | Stop auto-pick; recommend handoff |
| `uncertain_high` | Cannot estimate; risk of exceeding | Treat as `at_or_above_threshold` (conservative) |

When uncertain, favor handoff recommendation (conservative default). Recompute before each auto-pick attempt — do not cache across long idle periods.

### 2.8 Execution Mode Detection

APM supports two execution modes: **Manual Mode** (default) and **Autonomous Mode** (opt-in paired polling). Detect mode at Worker session initiation and re-evaluate at Work Queue Check entry.

**Session attribute:** `autonomous_mode_enabled` — parent gate that determines whether §3.7 may run.

**Detection procedure:**

ON session init OR before entering §3.7 Work Queue Check:

1. Read project Cursor rule file `.cursor/rules/apm-autonomous.mdc`. If present and declares Autonomous Execution Mode active, set `autonomous_mode_enabled = true`. Otherwise set `autonomous_mode_enabled = false`.
2. When Manual Mode (`autonomous_mode_enabled` false): set `polling_enabled = false`. Do not enter §3.7 until Autonomous Mode is active and gates permit entry.
3. Inform the operator which Execution Mode is active (Manual or Autonomous) and what it implies for this Worker session.
4. For mode semantics, coupling invariants, mismatch fallback, and stop behavior, read `{SKILL_PATH:apm-autonomous}`.

**Re-evaluation:** If the operator may have enabled or disabled Autonomous Mode mid-session (rule added or removed), re-run this procedure at §3.7 entry before other gates.

### 2.9 Mode Coupling Check

Run at §3.7 entry when `autonomous_mode_enabled` is true (immediately after §2.8). Skip when Manual Mode — no paired loop required.

**Purpose:** Enforce that Worker task polling and Manager report checking operate as an inseparable pair per `{SKILL_PATH:apm-autonomous}` §4 and FR-012.

**Procedure:**

WHEN `autonomous_mode_enabled` is true:

1. Re-read `.cursor/rules/apm-autonomous.mdc`. If absent OR does not declare Autonomous Execution Mode active → **coupling_fail** (reason: `rule_not_active`).
2. Assess Manager participation: IF no evidence the Manager will participate in autonomous coordination — e.g., operator confirms the Manager session is in Manual Mode, operator ran `{COMMAND_SLUG:autonomous} disable`, operator was explicitly directed to manual `{COMMAND_SLUG:review}`, or Tracker shows no Active coordination context for this Worker's dispatched Task AND operator indicates Manager is not running Autonomous Mode → **coupling_fail** (reason: `manager_not_participating`).
3. ELSE → **coupling_ok**.

**On coupling_fail:**

1. Announce:
   ```
   Autonomous Mode requires both Manager and Worker participation.
   Falling back to Manual Mode for this session.
   ```
2. Set `autonomous_mode_enabled = false`, `polling_enabled = false`.
3. Emit §3.7.3 Autonomous Session End Message.
4. Confirm the User is directed to deliver the Task Report to the Manager. Instruct the operator to run `{COMMAND_SLUG:task}` or `{COMMAND_SLUG:work}` when the next assignment arrives.
5. **Do not** enter the Work Queue Check loop. Stop (end turn).

**On coupling_ok:** Continue §3.7 from step 0 Autonomous branch — set `polling_enabled = true` and proceed to step 1.

---

## 3. Task Execution Procedure

Sequential flow from Task Prompt receipt through completion. Task Validation and the Correction Loop form a cycle that repeats until success or a stop condition.

### 3.1 Task Prompt Receipt

On Task receipt, perform the following actions:
1. Check for batch envelope: if Task Bus contains `batch: true` in frontmatter, it contains multiple Task Prompts separated by `---` delimiters. Execute each Task sequentially per §2.6 Batch Rules.
2. Verify `agent` in YAML frontmatter matches your assigned identity. Validate the bus directory matches `agent` per `{SKILL_PATH:apm-communication}` §4.1 Bus Identity Standards. If mismatch, decline per `{COMMAND_PATH:apm.work}` §5 Operating Rules.
3. If Workspace section present: switch to the specified branch or worktree path before starting work.
4. If `has_dependencies: true`, continue to Context Integration, otherwise proceed to §3.3 Task Execution.

### 3.2 Context Integration

Perform the following actions:
1. Read the Context from Dependencies section.
2. Execute integration based on dependency type per §2.1 Context Integration Standards:
   - **Cross-agent:** Follow integration steps completely - read files, review artifacts, understand interfaces. {WORKER_SUBAGENT_GUIDANCE} When a subagent returns findings, verify critical claims by reading the key files it references before proceeding - subagent summaries compress details and can misrepresent what matters for execution.
   - **Same-agent:** Use guidance to recall and build upon prior work; review referenced paths to refresh context if needed.
3. If integration issues discovered, apply decision rules from §2.1 Context Integration Standards.

### 3.3 Task Execution

Perform the following actions:
1. Execute Detailed Instructions sequentially, applying Guidance and relevant Rules from `{RULES_FILE}`, working toward the Objective.
2. When an instruction requires explicit User action, communicate what needs doing, why, and what options exist. Await completion, then resume.
3. When an instruction includes a subagent step, spawn the relevant subagent with a structured task description. Verify critical findings by reading key files the subagent references before integrating into execution. {WORKER_SUBAGENT_GUIDANCE}
4. When all instructions complete, communicate that implementation is complete and you are moving to validation. Continue to Task Validation.

### 3.4 Task Validation

Perform the following actions:
1. Execute autonomous checks from the Task Prompt's validation criteria per §2.2 Validation Standards: run tests, verify builds, confirm outputs exist and match expected structure. If any fail, continue to the correction loop. Ambiguous results: treat as failure and iterate; if iteration doesn't resolve, pause for guidance.
2. If criteria require User involvement: pause and present work per §2.2 Validation Standards. Communicate what was accomplished, what needs the User's review or action, where deliverables are located, and what to report back. If approved or completed, proceed to §3.6 Task Completion with Success status. If feedback provided, continue to the correction loop with feedback integrated.
3. If all criteria passed, proceed to §3.6 Task Completion with Success status.

### 3.5 Correction Loop

Perform the following actions:
1. Investigate the failure per §2.3 Iteration Standards: read error output, trace the cause, understand what went wrong.
2. Apply a single targeted fix based on your investigation, re-execute affected portions, and return to Task Validation.
3. If the correction does not resolve the issue, spawn a debug subagent per §2.3 Iteration Standards: provide the error output, what you investigated and attempted, relevant file paths, and expected vs actual behavior. Direct it to trace the root cause and propose a fix.
4. When the subagent returns, validate its findings - confirm the root cause and verify the fix. If sound, apply and return to Task Validation. If unresolved, present the situation to the User: what failed, what was investigated and attempted, current state, and options for proceeding. Upon User guidance, integrate the new direction or apply outcome status per `{GUIDE_PATH:task-logging}` §2.2 Outcome Standards and continue to Task Completion.

### 3.6 Task Completion

Perform the following actions:
1. Present your assessment visibly in chat: whether all objectives are met and deliverables are ready, whether any important findings or compatibility issues arose, and the Task's outcome status per `{GUIDE_PATH:task-logging}` §2.2 Outcome Standards.
2. Commit work to the assigned branch per §2.5 Version Control Standards.
3. Create Task Log per `{GUIDE_PATH:task-logging}` §3.1 Task Log Procedure at `log_path`.
4. Write Task Report per `{GUIDE_PATH:task-logging}` §3.2 Task Report Delivery. Include relevant status indications:
   - *After Handoff.* If this is the first Task after Handoff initialization, include incoming Worker indication: state instance number, list the specific Task Log files loaded, and note that previous-Stage logs were not loaded.
   - *After recovery:* If auto-compaction occurred and recovery was performed via `{COMMAND_SLUG:recover}`, note it in the Task Report so the Manager is aware.
5. Direct the User to deliver the Task Report to the Manager per `{GUIDE_PATH:task-logging}` §3.2 Task Report Delivery. When the Manager is actively polling for reports (Report Queue Check per `{GUIDE_PATH:task-review}` §3.8), writing the report to the Report Bus is sufficient — the Manager will detect it automatically; still provide delivery guidance for sessions where polling is inactive.
6. **Continue to Work Queue Check:** Proceed to §3.7 Work Queue Check Procedure. §3.7 step 0 Autonomous Mode gate determines whether polling runs or Manual Mode exit applies — when Autonomous Mode is active, run the poll script before sending any closing message; when Manual Mode, stop after delivery guidance per §3.7 step 0.

### 3.7 Work Queue Check Procedure

After Task Completion, automatically check the Task Bus for additional assignments when Autonomous Mode gates permit entry. When the queue is empty, run the polling script in a **same-turn agent loop** until work arrives, polling is stopped, or a higher-priority stop condition applies.

**Poll-until-stop (FR-017):** An empty Task Bus is **not** a stop condition. When the poll script returns `STILL_EMPTY`, run `sleep ${APM_POLL_INTERVAL:-10}` and call the check script again in the same conversation turn. **Do not** end the turn after a single empty check, idle announcement, or because Cursor aborted a long-running shell command — use repeated short shell calls instead. Continue until `WORK_FOUND`, `POLLING_STOPPED`, or a stop condition in §3.7.1 fires.

**Session attributes** (maintain during the session):
- `polling_enabled`: Whether automatic queue-check is active. **Manual Mode default: false** at session init (§2.8). **Autonomous Mode default: true** after §3.7 step 0 gate permits entry. Set false when operator stops polling, context threshold triggers, or Manual Mode is detected.
- `assignments_completed_this_session`: Count of Tasks completed this session (increment after each §3.6 completion)

**Scripts** (project root, shipped in `.apm/scripts/`):
- Check once: `bash .apm/scripts/poll-task-bus.sh <agent-slug>` (returns `WORK_FOUND`, `STILL_EMPTY`, or `POLLING_STOPPED`)
- Wait between checks: `sleep ${APM_POLL_INTERVAL:-10}` (separate short shell command)
- Stop button: `bash .apm/scripts/stop-task-polling.sh <agent-slug>`

**Polling model:** The Worker runs the check script and sleep in a **same-turn agent loop** — not one long-running bash process. Cursor aborts shell commands that run longer than ~60 seconds; giving up after a few checks is a procedure violation.

Perform the following actions:

0. **Autonomous Mode gate:** Run §2.8 Execution Mode Detection. Then:
   - **IF** `autonomous_mode_enabled` is false (**Manual Mode**): Confirm the User is directed to deliver the Task Report to the Manager. Instruct the operator to run `{COMMAND_SLUG:task}` or `{COMMAND_SLUG:work}` when the next assignment arrives. Set `polling_enabled = false`. **Do not** enter the Work Queue Check loop. Stop (end turn).
   - **IF** `autonomous_mode_enabled` is true (**Autonomous Mode**): Run §2.9 Mode Coupling Check. On **coupling_fail**, §2.9 handles Manual fallback and stop. On **coupling_ok**, set `polling_enabled = true` and continue to step 1.

1. **Report delivery reminder:** Confirm the User is directed to deliver the latest Task Report to the Manager. If any prior Task Reports from this session remain undelivered, remind the User to deliver those outstanding reports before or alongside proceeding with new work — auto-pickup does not waive report delivery obligations.

2. **Polling gate:** If `polling_enabled` is false, announce that automatic work polling is stopped. If polling was previously active this session, emit §3.7.3 Autonomous Session End Message. Await explicit operator instruction to resume. Stop (end turn).

3. **Stop condition evaluation:** Evaluate stop conditions per §3.7.1 before polling. If any apply (except operator stop via stop script, handled during poll), handle per §3.7.1 and stop (end turn).

4. **Start polling loop (agent-driven):** Verify `.apm/scripts/poll-task-bus.sh` exists. If missing, inform the operator that APM must be updated (`apm update` or project-equivalent) to install polling scripts — do not end turn awaiting `{COMMAND_SLUG:task}`.

   Remove any stale stop signal at `.apm/bus/<agent-slug>/polling.stop` if present. Inform the operator that work polling is active and display the stop command:

   ```bash
   bash .apm/scripts/stop-task-polling.sh <agent-slug>
   ```

   **Repeat** the following until `WORK_FOUND` or `POLLING_STOPPED` — do not end the turn, do not abort after a time limit or number of empty checks, and do not tell the operator to run `{COMMAND_SLUG:work}` again to resume polling. **`STILL_EMPTY` is not a stop signal** — always run sleep and return to step 4a:

   a. Run via shell tool:

   ```bash
   bash .apm/scripts/poll-task-bus.sh <agent-slug>
   ```

   b. Branch on output:
   - **`WORK_FOUND`:** Exit this loop; continue to step 5.
   - **`POLLING_STOPPED`:** Set `polling_enabled` false. Confirm polling was stopped via the stop button. Emit §3.7.3 Autonomous Session End Message. State how to resume (re-enable Autonomous Mode and re-engage `{COMMAND_SLUG:work}`, or use `{COMMAND_SLUG:task}` in Manual Mode). Stop (end turn).
   - **`STILL_EMPTY`:** Run a separate short wait, then return to step 4a:

   ```bash
   sleep ${APM_POLL_INTERVAL:-10}
   ```

5. **Read and validate Task Bus:** Read `.apm/bus/<agent-slug>/task.md` per `{SKILL_PATH:apm-communication}` §4 Message Bus Protocol.
   - **Invalid content:** Missing frontmatter, empty body, or unparseable structure — surface the error to the operator; do not execute. Stop (end turn).
   - **Misrouted assignment:** If `agent` in YAML frontmatter does not match registered identity, decline and alert the operator of a routing error. Do not clear the Task Bus; direct the operator to route to the correct Worker. Stop (end turn).
   - **Populated (valid assignment):** Continue to step 6.

6. **Context threshold assessment:** Assess session context utilization per §2.7 Session Context Assessment Standards before auto-picking. If threshold is met or uncertain-high, handle per §3.7.2 and stop (end turn).

7. **Auto-pick and execute:** Process the assignment per §3.1 Task Prompt Receipt through §3.6 Task Completion (including clearing the Task Bus per bus protocol on receipt). Increment `assignments_completed_this_session`.

8. **Same-turn exhaustion:** After completing step 7, return to step 2 (Work Queue Check loop) without ending the conversation turn — continue until polling is stopped, a stop condition applies, or `polling_enabled` is false.

#### 3.7.1 Stop Conditions

Evaluate in priority order when multiple conditions may apply:

| Priority | Condition | Action |
|----------|-----------|--------|
| 1 | Operator initiates Handoff | Follow `{COMMAND_PATH:apm.handoff.worker}`; set `polling_enabled` false; emit §3.7.3 Autonomous Session End Message; polling stops until new agent instance |
| 2 | Operator stop (stop button) | User runs `bash .apm/scripts/stop-task-polling.sh <agent-slug>` — poll script exits with `POLLING_STOPPED`; set `polling_enabled` false; emit §3.7.3 |
| 3 | Operator explicit stop (in chat) | User says "stop", "wait", "pause polling", or equivalent — set `polling_enabled` false; if currently polling, also run stop script or wait for next poll cycle; emit §3.7.3 |
| 4 | Context threshold met | Handle per §3.7.2 |
| 5 | Task Failed (batch fail-fast) | Per §2.6 Batch Rules — stop batch; after batch report, queue check may resume unless other stops apply |
| 6 | Misrouted assignment | Handled at step 5 |
| 7 | Invalid Task Bus content | Handled at step 5 |

When stopping due to context threshold with unprocessed assignments on the Task Bus, do NOT clear the Task Bus — preserve assignments for the incoming agent after Handoff.

#### 3.7.2 Context Threshold Stop

When session context assessment per §2.7 yields `at_or_above_threshold` or `uncertain_high`:
1. Do NOT begin additional queued assignments in the current session.
2. Inform the operator:
   - Estimated context utilization is high (~75% or uncertain)
   - Recommend initiating Handoff via `{COMMAND_SLUG:handoff.worker}`
   - Start a new agent via `{COMMAND_SLUG:work} <agent-id>`
   - Deliver any outstanding reports to the Manager before or during Handoff
3. If assignments remain on the Task Bus, state they are preserved for the incoming agent.
4. Set `polling_enabled` false until new session or operator explicitly re-engages execution.
5. Emit §3.7.3 Autonomous Session End Message.

#### 3.7.3 Autonomous Session End Message (FR-010)

When exiting an active autonomous Work Queue Check loop — stop script, operator explicit stop, Handoff, context threshold, coupling fail from autonomous state, or any §3.7.1 stop while `autonomous_mode_enabled` was true this session — emit before ending the turn:

```
Autonomous session has ended.
You may:
- Re-enable Autonomous Mode (ensure apm-autonomous rule is active, then continue with /apm.manage or /apm.work)
- Switch to manual coordination (/apm.review, /apm.task, /apm.work)
```

Preserve unprocessed Task Bus assignments and Report Bus content. Do not auto-re-enter §3.7 until the operator re-enables Autonomous Mode and re-engages execution.

---

## 4. Common Mistakes

- *Framework vocabulary in project output:* Commit messages, source comments, and code should describe the actual work - not the framework managing it. Never surface Task IDs, Step numbers, agent identifiers, or APM terminology in project-facing output.
- *Skipping cross-agent integration steps:* When cross-agent dependency context includes file reading instructions and integration guidance, completing those steps fully before starting implementation catches integration mismatches early. Proceeding on assumptions about another Worker's output leads to rework.
- *Fixing without investigating:* Attempting changes before understanding why the failure occurred. Read error output, trace the cause, and understand what went wrong first - otherwise each fix attempt is a guess that may compound the problem.
- *Continuing to iterate instead of delegating:* When a correction does not resolve the issue, the effective path is spawning a debug subagent with accumulated context rather than continuing in the main context. Each iteration consumes context budget and reduces reasoning quality - a subagent with fresh context is more effective.
- *Working non-incrementally:* Writing large deliverables in one pass without testing intermediate results. Build incrementally - compile, run, or validate after each meaningful step rather than producing everything and then discovering issues.
- *Logging Success with incomplete validation:* Marking a Task as Success when validation criteria were not fully exercised. If criteria cannot be met (missing resources, need User cooperation), log as Partial and explain what remains rather than claiming Success with caveats.
- *Ending turn instead of polling:* After Task Completion, telling the User to run `{COMMAND_SLUG:task}` or legacy names like `apm-4-check-tasks` instead of running the polling loop. Task Completion requires §3.7 polling when Autonomous Mode gates permit — not an idle handoff to the operator.
- *Aborting polling early:* Ending the turn after a few empty checks, after a single `STILL_EMPTY`, because Cursor aborted a long-running shell command, or telling the User to run `{COMMAND_SLUG:work}` again to resume. Use the agent-driven loop (check → sleep → check) indefinitely until `WORK_FOUND`, `POLLING_STOPPED`, or a §3.7.1 stop condition. An empty Task Bus alone is never a valid reason to end the turn while polling is active.
- *Treating idle as stop:* Announcing the Worker is idle-ready and ending the turn while `polling_enabled` remains true and no stop condition from §3.7.1 applies. Idle monitoring **is** polling — keep the same-turn loop running.

---

**End of Guide**
