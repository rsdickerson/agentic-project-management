# APM Opt-In Cursor Rules

Rules in this directory are **not installed by default**. Manual Mode remains the default coordination mode until an operator copies a rule into `.cursor/rules/`.

## apm-autonomous.mdc

Enables **Autonomous Execution Mode** — paired Worker task polling and Manager report checking.

```bash
mkdir -p .cursor/rules
cp templates/rules/apm-autonomous.mdc .cursor/rules/
```

Disable by removing `.cursor/rules/apm-autonomous.mdc` or running `/apm.autonomous disable`.

After `apm update`, rule templates are also available at `templates/rules/` in the project bundle.

## apm-cursor-polling-shell.mdc

**Cursor-only.** Sets Shell `block_until_ms` for poll script invocations so chunk waits (~50s) complete without the operator clicking **Run in background** (Cursor defaults to 30s).

```bash
cp templates/rules/apm-cursor-polling-shell.mdc .cursor/rules/
```

Recommended when using Autonomous Mode in Cursor. Safe to combine with `apm-autonomous.mdc`.
