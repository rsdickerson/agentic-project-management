# APM Polling Scripts

Polling is an **agent-driven loop** of short shell calls. Do not run a long-lived bash `while` loop — Cursor aborts shell commands after ~60 seconds.

Optional: set `APM_POLL_INTERVAL` (seconds, default `10`) for wait between checks.

---

## Worker Task Bus Polling

Workers use these scripts during Work Queue Check (see Task Execution Guide §3.7).

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

### Stop Worker polling (stop button)

```bash
bash .apm/scripts/stop-task-polling.sh <agent-slug>
```

Run from any terminal while the Worker is polling, or by the **Manager** after review when no `Ready` Tasks remain for that Worker. Detected on the Worker's next `poll-task-bus.sh` call.

Example:

```bash
bash .apm/scripts/stop-task-polling.sh backend-agent
```

---

## Manager Report Bus Polling

The Manager uses these scripts during Report Queue Check (see Task Review Guide §3.8).

### Check once (poll script)

```bash
bash .apm/scripts/poll-report-bus.sh
```

Prints `checking for reports...` and exits immediately:

| Output | Exit | Meaning |
|--------|------|---------|
| `REPORT_FOUND` + agent slug(s) | 0 | One or more Report Buses have content — process per Task Review §3 |
| `STILL_EMPTY` | 1 | No reports yet — sleep, then run this script again |
| `POLLING_STOPPED` | 2 | Operator triggered stop |

Scan scope: Workers with `Active` Tasks in the Tracker plus a health scan of all non-empty `.apm/bus/*/report.md` files (excluding `manager/`).

### Agent polling loop

After dispatch, the Manager repeats until `REPORT_FOUND` or `POLLING_STOPPED`:

```bash
bash .apm/scripts/poll-report-bus.sh
# if STILL_EMPTY:
sleep ${APM_POLL_INTERVAL:-10}
# repeat — do not end turn, do not give up after N checks
```

### Stop Manager report polling (stop button)

```bash
bash .apm/scripts/stop-report-polling.sh
```

Run from any terminal while the Manager is polling. Detected on the Manager's next `poll-report-bus.sh` call.
