#!/usr/bin/env bash
# Single Report Bus check for Manager report polling.
# The Manager agent calls this repeatedly in the same turn — NOT one long bash loop
# (Cursor aborts long-running shell commands after ~60 seconds).
#
# Usage: bash .apm/scripts/poll-report-bus.sh
#
# Exit codes:
#   0 - REPORT_FOUND (one or more non-empty Report Buses; slugs printed after header)
#   1 - STILL_EMPTY (Manager must sleep and call again)
#   2 - POLLING_STOPPED (operator ran stop-report-polling.sh)

set -euo pipefail

MANAGER_BUS=".apm/bus/manager"
STOP_FILE="${MANAGER_BUS}/report-polling.stop"
TRACKER=".apm/tracker.md"

echo "checking for reports..."

if [[ -f "$STOP_FILE" ]]; then
  rm -f "$STOP_FILE"
  echo "POLLING_STOPPED"
  exit 2
fi

FOUND_SLUGS=()

add_slug() {
  local slug="$1"
  local existing
  for existing in "${FOUND_SLUGS[@]:-}"; do
    [[ "$existing" == "$slug" ]] && return
  done
  FOUND_SLUGS+=("$slug")
}

check_report() {
  local slug="$1"
  local report_file=".apm/bus/${slug}/report.md"
  if [[ -s "$report_file" ]]; then
    add_slug "$slug"
  fi
}

# Active dispatches: Workers with Active Tasks in Tracker
if [[ -f "$TRACKER" ]]; then
  while IFS= read -r line; do
    if [[ "$line" =~ ^\|[[:space:]]*([0-9]+\.[0-9]+)[[:space:]]*\|[[:space:]]*Active[[:space:]]*\|[[:space:]]*([^|[:space:]]+)[[:space:]]*\| ]]; then
      check_report "${BASH_REMATCH[2]}"
    fi
  done < "$TRACKER"
fi

# Health scan: any non-empty Report Bus excluding manager/
shopt -s nullglob
for report_file in .apm/bus/*/report.md; do
  slug="$(basename "$(dirname "$report_file")")"
  [[ "$slug" == "manager" ]] && continue
  check_report "$slug"
done
shopt -u nullglob

if [[ ${#FOUND_SLUGS[@]} -gt 0 ]]; then
  echo "REPORT_FOUND"
  printf '%s\n' "${FOUND_SLUGS[@]}" | sort -u
  exit 0
fi

echo "STILL_EMPTY"
exit 1
