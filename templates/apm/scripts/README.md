# APM Polling Scripts

Polling uses **script-internal check/sleep loops** so the agent does not alternate poll + sleep shell calls every cycle (which creates chat UI noise in Cursor).

Each script invocation loops internally until `WORK_FOUND` / `REPORT_FOUND`, `POLLING_STOPPED`, or chunk timeout. On `STILL_EMPTY`, the agent re-invokes the script immediately in the same turn — **do not** run a separate `sleep` command.

Cursor aborts shell commands after ~60 seconds. Default `APM_POLL_CHUNK_SECONDS=50` keeps each invocation under that limit.

**Cursor IDE:** Install opt-in rule `templates/rules/apm-cursor-polling-shell.mdc` → `.cursor/rules/` so the agent sets Shell `block_until_ms` (default 30s is too short for a 50s chunk and triggers a manual **Run in background** prompt).

| Variable | Default | Description |
|----------|---------|-------------|
| `APM_POLL_INTERVAL` | 10 | Seconds between internal checks within one invocation |
| `APM_POLL_CHUNK_SECONDS` | 50 | Max wall time per invocation before returning `STILL_EMPTY` |

---

## Worker Task Bus Polling

Workers use these scripts during Work Queue Check (see Task Execution Guide §3.7).

### Poll script

```bash
bash .apm/scripts/poll-task-bus.sh <agent-slug>
```

Prints a machine token and exits (no human-readable status line — wait-state heartbeats are agent chat per apm-communication §2.4):

| Output | Exit | Meaning |
|--------|------|---------|
| `WORK_FOUND` | 0 | Task Bus has a pending assignment — execute it |
| `STILL_EMPTY` | 1 | Chunk elapsed with no work — re-invoke script immediately in same turn |
| `POLLING_STOPPED` | 2 | Operator triggered stop |

The script checks the Task Bus, sleeps `APM_POLL_INTERVAL`, and repeats until work arrives, stop is signaled, or the chunk timeout elapses.

### Agent polling loop

After Task Completion, the Worker repeats until `WORK_FOUND` or `POLLING_STOPPED`:

```bash
bash .apm/scripts/poll-task-bus.sh <agent-slug>
# if STILL_EMPTY: re-invoke immediately — do not run separate sleep
# repeat — do not end turn, do not give up after N checks
```

Apply wait-state suppression in chat per §2.4 on each `STILL_EMPTY` — one tool block per chunk, not per internal check.

### Stop Worker polling (stop button)

```bash
bash .apm/scripts/stop-task-polling.sh <agent-slug>
```

Run from any terminal while the Worker is polling, or by the **Manager** after review when no `Ready` Tasks remain for that Worker. Detected on the Worker's next internal check (within `APM_POLL_INTERVAL`).

Example:

```bash
bash .apm/scripts/stop-task-polling.sh backend-agent
```

---

## Manager Report Bus Polling

The Manager uses these scripts during Report Queue Check (see Task Review Guide §3.8).

### Poll script

```bash
bash .apm/scripts/poll-report-bus.sh
```

Prints a machine token and exits (no human-readable status line — wait-state heartbeats are agent chat per apm-communication §2.4):

| Output | Exit | Meaning |
|--------|------|---------|
| `REPORT_FOUND` + agent slug(s) | 0 | One or more Report Buses have content — process per Task Review §3 |
| `STILL_EMPTY` | 1 | Chunk elapsed with no reports — re-invoke script immediately in same turn |
| `POLLING_STOPPED` | 2 | Operator triggered stop |

Scan scope: Workers with `Active` Tasks in the Tracker plus a health scan of all non-empty `.apm/bus/*/report.md` files (excluding `manager/`).

### Agent polling loop

After dispatch, the Manager repeats until `REPORT_FOUND` or `POLLING_STOPPED`:

```bash
bash .apm/scripts/poll-report-bus.sh
# if STILL_EMPTY: re-invoke immediately — do not run separate sleep
# repeat — do not end turn, do not give up after N checks
```

### Stop Manager report polling (stop button)

```bash
bash .apm/scripts/stop-report-polling.sh
```

Run from any terminal while the Manager is polling. Detected on the Manager's next internal check (within `APM_POLL_INTERVAL`).

---

## Stale stop cleanup (session entry)

Stop files can remain if a prior session ended before the poll script consumed them. **Do not** let the first poll return `POLLING_STOPPED` for a leftover file — clear at session init instead.

```bash
bash .apm/scripts/clear-stale-polling-stop.sh manager
bash .apm/scripts/clear-stale-polling-stop.sh <agent-slug>
```

| Output | Meaning |
|--------|---------|
| `STALE_STOP_CLEARED` | File existed and was removed — not a stop event |
| `NO_STOP_FILE` | Nothing to clear |

- **Manager:** run at every `{COMMAND_SLUG:manage}` entry (before first poll).
- **Worker:** run at every `{COMMAND_SLUG:work}` entry (before first poll).

Does **not** emit `POLLING_STOPPED`. Safe to run even when no stop file exists.
