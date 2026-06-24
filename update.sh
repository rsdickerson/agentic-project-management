TMP=$(mktemp -d) && \
unzip -qo ~/source/github/agentic-project-management/dist/cursor.zip -d "$TMP" && \
rm -rf .cursor/commands .cursor/apm-guides .cursor/skills .cursor/agents && \
cp -r "$TMP/.cursor/commands" "$TMP/.cursor/apm-guides" "$TMP/.cursor/skills" "$TMP/.cursor/agents" .cursor/ && \
mkdir -p .apm && \
cp -r "$TMP/.apm/scripts" .apm/ && \
rm -rf "$TMP"