#!/usr/bin/env bash
# Dev helper: install built Cursor templates and APM polling scripts into this repo.
# Run from repository root: ./update.sh
#
# Installs:
#   .cursor/commands, .cursor/apm-guides, .cursor/skills, .cursor/agents  (from dist/cursor.zip)
#   .apm/scripts/*                                                         (from templates/apm/scripts)
#
# Does NOT install opt-in Cursor rules (Manual Mode remains default). Rule templates ship in
# templates/rules/ inside dist/cursor.zip and in templates/rules/ at repo root for dev.
# Enable Autonomous Mode: cp templates/rules/apm-autonomous.mdc .cursor/rules/

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

RULES_TEMPLATES="${REPO_ROOT}/templates/rules"

echo "APM dev install complete."
echo "Cursor templates: ${CURSOR_DIR}"
echo "Polling scripts:"
ls -1 "$APM_SCRIPTS_DIR"
echo ""
echo "Opt-in Cursor rules (NOT installed by default — Manual Mode remains default):"
if [[ -d "$RULES_TEMPLATES" ]]; then
  ls -1 "${RULES_TEMPLATES}/"*.mdc 2>/dev/null || echo "  (none)"
  echo "  Enable Autonomous Mode: cp templates/rules/apm-autonomous.mdc .cursor/rules/"
else
  echo "  (templates/rules not found at ${RULES_TEMPLATES})"
fi
