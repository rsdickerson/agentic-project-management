---
title: Hello Daily Content
modified: Spec creation by the Planner.
---

# APM Spec

## Overview

Hello Daily Content is a Python CLI application that prints a fixed-order daily digest of local and live content to standard output in a single no-argument invocation (`python -m hello`). The project is built greenfield from the authoritative feature pack at `specs/001-hello-daily-content/`, extended with a multilingual greeting that randomly selects from a pool of at least 100 languages stored in an external data file. Success requires a working CLI that passes an offline pytest suite, shell scripts for build/test/run, a README adapted from the feature quickstart, and a module-per-section architecture that supports parallel autonomous agent development.

## Workspace

| Aspect | Detail |
|--------|--------|
| **Repository** | Single repo at workspace root (`hola`); git initialized on `main`, no commits yet |
| **Working target** | Repository root — `src/hello/`, `tests/`, `pyproject.toml`, shell scripts, `README.md` |
| **Reference materials** | `specs/001-hello-daily-content/` (authoritative requirements and contracts); not modified during implementation unless the User directs |
| **Application code** | None present — full greenfield build |
| **`AGENTS.md`** | Does not exist yet; created during Work Breakdown with APM_RULES block |

---

> **Notes:** Fresh repository with no commit history — the Manager will establish version control conventions at Implementation Phase start. The feature spec pack predates the multilingual greeting change; greeting behavior in this Spec supersedes `specs/001-hello-daily-content/spec.md` FR-003 and related greeting references where they conflict. Primary exercise goal is both a passing application and exercising APM parallel agent coordination.

## Authoritative Requirements

Core functional requirements, user stories, acceptance scenarios, and success criteria are defined in `specs/001-hello-daily-content/spec.md`. This Spec captures design decisions layered on that document. The Manager should extract per-Task requirements from the feature spec and the sections below.

**Contracts (implementation targets):**

| Document | Scope |
|----------|-------|
| `specs/001-hello-daily-content/contracts/cli-output.md` | Print order, section formats, failure placeholders, test contract |
| `specs/001-hello-daily-content/contracts/http-modules.md` | HTTP helper API, per-module requirements, URL registry |
| `specs/001-hello-daily-content/data-model.md` | In-memory entity shapes and section relationships |
| `specs/001-hello-daily-content/research.md` | API source decisions for Word of the Day and Learn Spanish |

Where this Spec conflicts with the feature spec on greeting behavior, this Spec governs.

## Technology Stack

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Language | Python 3.10+ | Matches feature pack; supports `list[str]` typing |
| Runtime dependencies | Stdlib only (`urllib`, `json`, `html`) | Per feature pack constitution |
| Dev dependencies | `pytest` via `pyproject.toml` dependency group | Offline test validation |
| Packaging | `pyproject.toml` with editable install (`pip install -e .`) | Standard Python CLI layout |
| HTTP | Shared `hello.http` module with `fetch_json` and `fetch_text` | Centralized timeout and error handling |
| Entry point | `python -m hello` via `src/hello/__main__.py` | Per feature pack |

No additional runtime libraries, API keys, configuration files, persistent storage, or interactive input.

## Application Architecture

### Layout

```text
src/hello/           # One module per content section + http + orchestrator
tests/               # One test module per section + integration test
pyproject.toml
build.sh / test.sh / run.sh
README.md
```

### Module-per-section pattern

Each content section is an independent Python module under `src/hello/` exposing a public fetch function. The orchestrator (`hello.main` in `__init__.py`) calls each module in order and prints results. Feature modules MUST NOT print directly.

| Module type | Public API | Return type |
|-------------|------------|-------------|
| Single-line | `fetch_<section>_line()` | `str` |
| Multi-line | `fetch_<section>_lines()` | `list[str]` or `str` (unavailable placeholder) |

Multi-line sections (joke, word of the day, Spanish) follow the joke precedent: success returns a list of lines; failure returns a single unavailable placeholder string.

### Print order

Sections MUST appear in this exact sequence (per `contracts/cli-output.md`, authoritative for output):

1. Greeting (1 line)
2. Banner (5 lines)
3. Weather, DOW, Joke, Quote, Word of the day, Fact, Activity, Dog fact, Cat fact, Trivia, Number, Spanish, Advice

Total: 15 logical sections; 18–20 stdout lines when all optional sub-lines present.

### Exit behavior

The program MUST always exit with code `0` after printing all sections, regardless of how many live sections failed.

## Greeting Design

This section supersedes `specs/001-hello-daily-content/spec.md` FR-003 and the default greeting in `contracts/cli-output.md`.

| Decision | Specification |
|----------|---------------|
| Selection | Random choice from a fixed pool on each run (`random` module); repeats across runs are acceptable |
| Pool size | Minimum 100 entries, each a distinct language |
| Storage | External data file loaded at runtime (not inline in Python source) — e.g. `src/hello/greetings.json` |
| Output format | `{foreign_greeting} ({Language name})` — language name in English (e.g. `¡Hola! (Spanish)`) |
| Network | None — greeting is a local section; no external fetch |
| Testing | Tests patch `random` to pin deterministic selection; integration tests assert full stdout with pinned greeting |

Data file schema (minimum fields per entry):

```json
{ "greeting": "¡Hola!", "language": "Spanish" }
```

The `greeting.py` module loads this file, selects randomly, and formats the output line.

## Local Content

### Banner

Fixed five-line ASCII art block, deterministic on every run. Stored in `banner.py` (inline constant list). No network access.

## Live Content Sections

Each live section fetches from a public API at runtime, formats output per `contracts/cli-output.md`, and handles failures independently.

| Property | Requirement |
|----------|-------------|
| Timeout | 10 seconds per request (`DEFAULT_TIMEOUT` in `hello.http`) |
| Failure handling | Catch network/parse errors internally; return section-specific `{Label}: unavailable` placeholder; never raise to orchestrator |
| User-Agent | Use `user_agent=True` on endpoints that block default urllib (known: `dow`, `cat`; verify others during implementation) |
| Trivia | Decode HTML entities for display |
| DOW | Format price with comma thousands separators and exactly two decimal places |
| Joke | Success: two unprefixed lines (setup, punchline); failure: `Joke: unavailable` |

### New sections (API sources per `research.md`)

| Section | Flow |
|---------|------|
| Word of the day | Random Word API (text) → Free Dictionary API (JSON); optional example line |
| Learn Spanish | Random Word API `lang=es` (text) → MyMemory translation (JSON); optional tip line |

### URL registry

Existing section URLs are preserved in `contracts/http-modules.md`. New section URLs follow `research.md`. No API keys required.

## HTTP Layer

`hello.http` provides:

| Function | Purpose |
|----------|---------|
| `fetch_json(url, *, user_agent=False)` | GET JSON; 10s timeout |
| `fetch_text(url, *, user_agent=False)` | GET plain text; 10s timeout |

Constants: `DEFAULT_TIMEOUT = 10`, `USER_AGENT = "Mozilla/5.0"`.

## Testing Strategy

| Requirement | Detail |
|-------------|--------|
| Framework | pytest |
| Network | No live API calls during `pytest` — patch `urllib.request.urlopen` |
| Unit tests | One `tests/test_<module>.py` per section; assert exact return string(s) |
| Integration | `tests/test_hello.py` mocks all URLs; asserts **complete** stdout string including every trailing newline |
| Greeting | Patch `random` for deterministic integration and unit tests |
| Failure isolation | Tests verify single-section failure shows only that section's placeholder |

## Shell Scripts and Documentation

| Artifact | Behavior |
|----------|----------|
| `build.sh` | Create venv (if needed), `pip install -e .`, install pytest dev dependency |
| `test.sh` | Run `pytest` |
| `run.sh` | Run `python -m hello` |
| `README.md` | Adapted from `specs/001-hello-daily-content/quickstart.md` — prerequisites, setup, build/test/run, validation scenarios |

No Makefile. No `clean` target required.

## Out of Scope

- CI/CD pipeline configuration
- Linting/formatting tooling beyond pytest
- GUI, structured JSON output, logging files
- Interactive input or configuration files
- API key authentication
- Modifying the feature spec pack documents during implementation

## Success Criteria

| Criterion | Measure |
|-----------|---------|
| Complete digest | `python -m hello` prints all 15 sections in order and exits 0 |
| Offline tests | `pytest` passes with no network access |
| Greeting | Random multilingual greeting from ≥100-entry data file with language name |
| Resilience | Any single live section failure shows only its placeholder; others unaffected |
| Parallel buildability | Each section module independently implementable and testable per contracts |
| Scripts | `build.sh`, `test.sh`, `run.sh` execute successfully from repo root |
