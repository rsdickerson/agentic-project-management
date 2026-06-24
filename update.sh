#!/usr/bin/env bash
# Dev helper: install built Cursor templates and APM polling scripts into this repo.
# Run from repository root: ./update.sh
#
# Installs:
#   .cursor/commands, .cursor/apm-guides, .cursor/skills, .cursor/agents  (from dist/cursor.zip)
#   .apm/scripts/*                                                         (from templates/apm/scripts)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST_ZIP="${REPO_ROOT}/dist/cursor.zip"
TEMPLATES_SCRIPTS="${REPO_ROOT}/templates/apm/scripts"
CURSOR_DIR="${REPO_ROOT}/.cursor"
APM_SCRIPTS_DIR="${REPO_ROOT}/.apm/scripts"

if [[ ! -f "$DIST_ZIP" ]]; then
  echo "dist/cursor.zip not found — running npm run build..."
  (cd "$REPO_ROOT" && npm run build)
fi

if [[ ! -d "$TEMPLATES_SCRIPTS" ]]; then
  echo "ERROR: templates/apm/scripts not found at ${TEMPLATES_SCRIPTS}" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

unzip -qo "$DIST_ZIP" -d "$TMP"

rm -rf \
  "${CURSOR_DIR}/commands" \
  "${CURSOR_DIR}/apm-guides" \
  "${CURSOR_DIR}/skills" \
  "${CURSOR_DIR}/agents"
mkdir -p "$CURSOR_DIR"
cp -R "$TMP/.cursor/commands" \
      "$TMP/.cursor/apm-guides" \
      "$TMP/.cursor/skills" \
      "$TMP/.cursor/agents" \
      "$CURSOR_DIR/"

rm -rf "$APM_SCRIPTS_DIR"
mkdir -p "$APM_SCRIPTS_DIR"
cp -f "${TEMPLATES_SCRIPTS}/"*.sh "${TEMPLATES_SCRIPTS}/README.md" "$APM_SCRIPTS_DIR/"
chmod +x "${APM_SCRIPTS_DIR}/"*.sh

echo "APM dev install complete."
echo "Cursor templates: ${CURSOR_DIR}"
echo "Polling scripts:"
ls -1 "$APM_SCRIPTS_DIR"
