# PrimeCouncil

## What this is
Multi-LLM orchestration framework. Claude = orchestrator/synthesizer/executor.
Codex = the independent reviewer. Human = strategic supervisor.

## Status
Framework complete. Post-first-run hardening done. Ready for production use.

## Stack
- Python (runner), Bash (reviewer scripts)
- Codex CLI (reviewer invocation)
- Claude Code (orchestrator environment)

## Key directories
- `.claude/primecouncil/` — runner, scripts, config, templates, docs, run history, AGENTS.md
- `.claude/skills/` — prime-orch, prime-save, prime-resume, prime-install
- `.claude/primecouncil/docs/` — protocol detail, packet spec, runs spec, host-repo pattern, user tutorial

## Key conventions
- Runner handles all mechanical file operations — never create task folders manually
- AGENTS.md is shared reviewer constitution — loaded on demand, not every turn
- All reviewer output saved as artifacts — raw + normalized reviews

For project orientation, see `docs/project-context.md` if present — but do not rely on it entirely. Follow the key files it references to get the full context when needed.

<!-- PRIMECOUNCIL:START - Do not edit this section manually -->
## PrimeCouncil

Multi-LLM orchestration, activated by `/prime-orch`. State lives in
`.claude/primecouncil/orch-state.json`; missing means `{"orch": "off", "default_mode": "manual"}`.

**If `orch` is `"on"`, or the user issues an `ORCH ON` / `MODE` / `GO` command, read
`.claude/primecouncil/ORCHESTRATION.md` with the Read tool — never `@import` — and follow it.**
It owns the commands, the modes, and what else to load when; `ORCH OFF` only updates the state
file. After `/compact` or a session reset, re-read the state file — and the contract too, if
`orch` is on.
<!-- PRIMECOUNCIL:END -->
