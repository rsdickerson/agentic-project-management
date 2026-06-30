#!/usr/bin/env bash
# Report Bus polling — internal check/sleep loop until reports, stop, or chunk timeout.
# The Manager agent re-invokes this script on STILL_EMPTY in the same turn.
# Cursor aborts shell commands after ~60s; default chunk stays under that limit.
#
# Usage: bash .apm/scripts/poll-report-bus.sh
#
# Environment:
#   APM_POLL_INTERVAL       seconds between internal checks (default 10)
#   APM_POLL_CHUNK_SECONDS  max wall time per invocation (default 50)
#
# Exit codes:
#   0 - REPORT_FOUND (one or more non-empty Report Buses; slugs printed after header)
#   1 - STILL_EMPTY (chunk elapsed — agent re-invokes immediately)
#   2 - POLLING_STOPPED (operator ran stop-report-polling.sh)

set -euo pipefail

MANAGER_BUS=".apm/bus/manager"
STOP_FILE="${MANAGER_BUS}/report-polling.stop"
TRACKER=".apm/tracker.md"
INTERVAL="${APM_POLL_INTERVAL:-10}"
CHUNK="${APM_POLL_CHUNK_SECONDS:-50}"

FOUND_SLUGS=()

add_slug() {
  local slug="$1"
  local existing
  for existing in "${FOUND_SLUGS[@]:-}"; do
    [[ "$existing" == "$slug" ]] && return
  done
  FOUND_SLUGS+=("$slug")
}

check_reports() {
  FOUND_SLUGS=()

  if [[ -f "$TRACKER" ]]; then
    while IFS= read -r line; do
      if [[ "$line" =~ ^\|[[:space:]]*([0-9]+\.[0-9]+)[[:space:]]*\|[[:space:]]*Active[[:space:]]*\|[[:space:]]*([^|[:space:]]+)[[:space:]]*\| ]]; then
        local report_file=".apm/bus/${BASH_REMATCH[2]}/report.md"
        if [[ -s "$report_file" ]]; then
          add_slug "${BASH_REMATCH[2]}"
        fi
      fi
    done < "$TRACKER"
  fi

  shopt -s nullglob
  for report_file in .apm/bus/*/report.md; do
    local slug
    slug="$(basename "$(dirname "$report_file")")"
    [[ "$slug" == "manager" ]] && continue
    if [[ -s "$report_file" ]]; then
      add_slug "$slug"
    fi
  done
  shopt -u nullglob
}

deadline=$(( SECONDS + CHUNK ))

while true; do
  if [[ -f "$STOP_FILE" ]]; then
    rm -f "$STOP_FILE"
    echo "POLLING_STOPPED"
    exit 2
  fi

  check_reports

  if [[ ${#FOUND_SLUGS[@]} -gt 0 ]]; then
    echo "REPORT_FOUND"
    printf '%s\n' "${FOUND_SLUGS[@]}" | sort -u
    exit 0
  fi

  if (( SECONDS >= deadline )); then
    echo "STILL_EMPTY"
    exit 1
  fi

  sleep "$INTERVAL"
done
