#!/usr/bin/env bash
# Single Task Bus check for work polling.
# The Worker agent calls this repeatedly in the same turn — NOT one long bash loop
# (Cursor aborts long-running shell commands after ~60 seconds).
#
# Usage: bash .apm/scripts/poll-task-bus.sh <agent-slug>
#
# Exit codes:
#   0 - WORK_FOUND (task.md has content)
#   1 - STILL_EMPTY (agent must sleep and call again)
#   2 - POLLING_STOPPED (operator ran stop-task-polling.sh)

set -euo pipefail

AGENT_SLUG="${1:?Usage: poll-task-bus.sh <agent-slug>}"
BUS_DIR=".apm/bus/${AGENT_SLUG}"
TASK_BUS="${BUS_DIR}/task.md"
STOP_FILE="${BUS_DIR}/polling.stop"

if [[ ! -d "$BUS_DIR" ]]; then
  echo "ERROR: Bus directory not found: ${BUS_DIR}" >&2
  exit 1
fi

echo "checking for work..."

if [[ -f "$STOP_FILE" ]]; then
  rm -f "$STOP_FILE"
  echo "POLLING_STOPPED"
  exit 2
fi

if [[ -s "$TASK_BUS" ]]; then
  echo "WORK_FOUND"
  exit 0
fi

echo "STILL_EMPTY"
exit 1
