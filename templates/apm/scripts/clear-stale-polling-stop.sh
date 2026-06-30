#!/usr/bin/env bash
# Remove leftover polling stop files from a prior session.
# Does NOT emit POLLING_STOPPED — safe to run at session init before the first poll.
#
# Usage:
#   bash .apm/scripts/clear-stale-polling-stop.sh manager
#   bash .apm/scripts/clear-stale-polling-stop.sh <agent-slug>
#
# Output:
#   STALE_STOP_CLEARED — file existed and was removed
#   NO_STOP_FILE       — nothing to clear

set -euo pipefail

TARGET="${1:?Usage: clear-stale-polling-stop.sh manager|<agent-slug>}"

if [[ "$TARGET" == "manager" ]]; then
  STOP_FILE=".apm/bus/manager/report-polling.stop"
else
  STOP_FILE=".apm/bus/${TARGET}/polling.stop"
fi

if [[ -f "$STOP_FILE" ]]; then
  rm -f "$STOP_FILE"
  echo "STALE_STOP_CLEARED"
  exit 0
fi

echo "NO_STOP_FILE"
exit 0
