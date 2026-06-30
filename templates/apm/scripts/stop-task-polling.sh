#!/usr/bin/env bash
# Stop button for Worker task polling — signals poll-task-bus.sh to exit.
# Usage: bash .apm/scripts/stop-task-polling.sh <agent-slug>
#
# Run from any terminal while the Worker is polling. The poll loop checks
# for this signal on each iteration; the next poll-task-bus.sh returns POLLING_STOPPED.

set -euo pipefail

AGENT_SLUG="${1:?Usage: stop-task-polling.sh <agent-slug>}"
BUS_DIR=".apm/bus/${AGENT_SLUG}"
STOP_FILE="${BUS_DIR}/polling.stop"

mkdir -p "$BUS_DIR"
touch "$STOP_FILE"

echo "Stop signal sent for ${AGENT_SLUG}."
echo "Polling will stop at the next check (within ${APM_POLL_INTERVAL:-10}s)."
