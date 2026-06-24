#!/usr/bin/env bash
# Stop button for Manager report polling — signals poll-report-bus.sh to exit.
# Usage: bash .apm/scripts/stop-report-polling.sh
#
# Run from any terminal while the Manager is polling. The poll loop checks
# for this signal on each iteration and stops at the next "checking for reports..." cycle.

set -euo pipefail

MANAGER_BUS=".apm/bus/manager"
STOP_FILE="${MANAGER_BUS}/report-polling.stop"

mkdir -p "$MANAGER_BUS"
touch "$STOP_FILE"

echo "Stop signal sent for Manager report polling."
echo "Polling will stop at the next check (within ${APM_POLL_INTERVAL:-10}s)."
