---
command_name: task
description: Read and execute work assigned on the Task Bus.
---

# APM {VERSION} - Worker Task Command

Read and execute work assigned on your Task Bus. If you are a Planner, Manager, or non-APM agent, concisely decline and take no action. This command replaces manual file referencing - you resolve your bus path from your registered identity or from the provided `[agent-id]` argument.

Accepts an optional `[agent-id]` argument. If registered, ignore it (bus path already known). If not registered, the argument is required to resolve identity.

**Procedure:**
1. Determine registration state:
   - If registered, resolve bus path from registration. Continue to step 3.
   - If not registered, `{ARGS}` is required. If no argument provided, inform User that an agent-id is required.

2. Resolve agent-id (unregistered Workers only): resolve `{ARGS}` against `.apm/bus/` directory names per `{SKILL_PATH:apm-communication}` §4.2 Agent ID Resolution. Initialize per `{COMMAND_PATH:apm.work}` §2 Initiation.

3. Read Task Bus at `.apm/bus/<agent-slug>/task.md`.
   - If empty, inform User that no pending Task is available. Await next invocation.
   - If content present, continue to step 4.

4. Cross-validate `agent` field in YAML frontmatter against registered identity. Mismatch flags a routing error - decline and direct User to the correct Worker. Process the Task per `{GUIDE_PATH:task-execution}` §3 Task Execution Procedure.

**Primary Manual Mode path (FR-009):** When Autonomous Mode is inactive (default), this command is the **primary** next-task delivery path at the task-delivery boundary. After completing an assignment, the Worker stops after single-run execution and the operator runs `{COMMAND_SLUG:task}` (or `{COMMAND_SLUG:work}`) when the next assignment arrives — the Worker does not enter automatic task polling per `{GUIDE_PATH:task-execution}` §3.7.

**Init trigger:** Required when the Worker is not yet registered (step 2 resolves identity and initializes per `{COMMAND_PATH:apm.work}` §2.1).

**Autonomous Mode fallback:** When Autonomous Mode is active, initialized Workers automatically check the Task Bus after each assignment via `{GUIDE_PATH:task-execution}` §3.7 and operators typically do not need this command at the task-delivery boundary. Use this command when autonomous task polling is inactive — after polling was stopped, when Autonomous Mode has ended, or when the operator wants explicit control to force a queue check.

---

**End of Command**
