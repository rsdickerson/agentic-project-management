# APM Worker Scripts

## Task Bus Polling

Workers use these scripts during Work Queue Check (see Task Execution Guide §3.7).

**Important:** Polling is an **agent-driven loop** of short shell calls. Do not run a long-lived bash `while` loop — Cursor aborts shell commands after ~60 seconds.

### Check once (poll script)

```bash
bash .apm/scripts/poll-task-bus.sh <agent-slug>
```

Prints `checking for work...` and exits immediately:

| Output | Exit | Meaning |
|--------|------|---------|
| `WORK_FOUND` | 0 | Task Bus has a pending assignment — execute it |
| `STILL_EMPTY` | 1 | No work yet — sleep, then run this script again |
| `POLLING_STOPPED` | 2 | Operator triggered stop |

### Agent polling loop

After Task Completion, the Worker repeats until `WORK_FOUND` or `POLLING_STOPPED`:

```bash
bash .apm/scripts/poll-task-bus.sh <agent-slug>
# if STILL_EMPTY:
sleep ${APM_POLL_INTERVAL:-10}
# repeat — do not end turn, do not give up after N checks
```

Optional: set `APM_POLL_INTERVAL` (seconds, default `10`) for wait between checks.

### Stop polling (stop button)

```bash
bash .apm/scripts/stop-task-polling.sh <agent-slug>
```

Run from any terminal while the Worker is polling, or by the **Manager** after review when no `Ready` Tasks remain for that Worker. Detected on the Worker's next `poll-task-bus.sh` call.

Example:

```bash
bash .apm/scripts/stop-task-polling.sh backend-agent
```
