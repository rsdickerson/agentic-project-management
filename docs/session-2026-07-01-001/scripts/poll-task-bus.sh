#!/usr/bin/env bash
# Task Bus polling — internal check/sleep loop until work, stop, or chunk timeout.
# The Worker agent re-invokes this script on STILL_EMPTY in the same turn.
# Cursor aborts shell commands after ~60s; default chunk stays under that limit.
#
# Usage: bash .apm/scripts/poll-task-bus.sh <agent-slug>
#
# Environment:
#   APM_POLL_INTERVAL       seconds between internal checks (default 10)
#   APM_POLL_CHUNK_SECONDS  max wall time per invocation (default 50)
#
# Exit codes:
#   0 - WORK_FOUND (task.md has content)
#   1 - STILL_EMPTY (chunk elapsed — agent re-invokes immediately)
#   2 - POLLING_STOPPED (operator ran stop-task-polling.sh)

set -euo pipefail

AGENT_SLUG="${1:?Usage: poll-task-bus.sh <agent-slug>}"
BUS_DIR=".apm/bus/${AGENT_SLUG}"
TASK_BUS="${BUS_DIR}/task.md"
STOP_FILE="${BUS_DIR}/polling.stop"
INTERVAL="${APM_POLL_INTERVAL:-10}"
CHUNK="${APM_POLL_CHUNK_SECONDS:-50}"

if [[ ! -d "$BUS_DIR" ]]; then
  echo "ERROR: Bus directory not found: ${BUS_DIR}" >&2
  exit 1
fi

deadline=$(( SECONDS + CHUNK ))

while true; do
  if [[ -f "$STOP_FILE" ]]; then
    rm -f "$STOP_FILE"
    echo "POLLING_STOPPED"
    exit 2
  fi

  if [[ -s "$TASK_BUS" ]]; then
    echo "WORK_FOUND"
    exit 0
  fi

  if (( SECONDS >= deadline )); then
    echo "STILL_EMPTY"
    exit 1
  fi

  sleep "$INTERVAL"
done
