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
