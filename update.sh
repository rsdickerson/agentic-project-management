#!/usr/bin/env bash
# Dev helper: install built Cursor templates and APM polling scripts into a project.
#
# Usage:
#   ./update.sh                    # install into this repo (APM development)
#   ./update.sh /path/to/project     # install into another project (e.g. hello lab)
#
# Installs:
#   .cursor/commands, .cursor/apm-guides, .cursor/skills, .cursor/agents  (from dist/cursor.zip)
#   .apm/scripts/*                                                         (from templates/apm/scripts)
#   templates/rules/*                                                      (opt-in rule templates; NOT copied to .cursor/rules/)
#
# Does NOT install opt-in Cursor rules into .cursor/rules/ (Manual Mode remains default).
# Enable Autonomous Mode: cp templates/rules/apm-autonomous.mdc .cursor/rules/
# Cursor polling shell (optional): cp templates/rules/apm-cursor-polling-shell.mdc .cursor/rules/

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$REPO_ROOT}"
TARGET="$(cd "$TARGET" && pwd)"

DIST_ZIP="${REPO_ROOT}/dist/cursor.zip"
TEMPLATES_SCRIPTS="${REPO_ROOT}/templates/apm/scripts"
CURSOR_DIR="${TARGET}/.cursor"
APM_SCRIPTS_DIR="${TARGET}/.apm/scripts"
RULES_DEST="${TARGET}/templates/rules"

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

if [[ -d "$TMP/templates/rules" ]]; then
  mkdir -p "$RULES_DEST"
  cp -f "$TMP/templates/rules/"*.mdc "$TMP/templates/rules/README.md" "$RULES_DEST/"
else
  echo "WARN: templates/rules not found in dist/cursor.zip — skipping rule templates" >&2
fi

echo "APM dev install complete."
echo "Target project: ${TARGET}"
echo "Cursor templates: ${CURSOR_DIR}"
echo "Polling scripts: ${APM_SCRIPTS_DIR}"
ls -1 "$APM_SCRIPTS_DIR"
echo ""
echo "Opt-in Cursor rules (NOT installed by default — Manual Mode remains default):"
if [[ -d "$RULES_DEST" ]]; then
  ls -1 "${RULES_DEST}/"*.mdc 2>/dev/null || echo "  (none)"
  echo "  Enable Autonomous Mode:"
  echo "    cp templates/rules/apm-autonomous.mdc .cursor/rules/"
  echo "  Cursor polling shell (optional, from project root):"
  echo "    cp templates/rules/apm-cursor-polling-shell.mdc .cursor/rules/"
else
  echo "  (templates/rules not installed — run npm run build and retry)"
fi
