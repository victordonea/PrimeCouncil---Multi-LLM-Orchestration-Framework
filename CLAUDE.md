# PrimeCouncil

## What this is
Multi-LLM orchestration framework. Claude = orchestrator/synthesizer/executor.
Codex + Gemini = independent reviewers. Human = strategic supervisor.

## Status
Framework complete. Post-first-run hardening done. Ready for production use.

## Stack
- Python (runner), Bash (reviewer scripts)
- Codex CLI, Gemini CLI (reviewer invocation)
- Claude Code (orchestrator environment)

## Key directories
- `primecouncil/` — runner, scripts, config, templates, docs, run history
- `.claude/skills/` — prime-orch, prime-save, prime-resume, prime-install
- `primecouncil/docs/` — protocol detail, packet spec, runs spec, project context

## Key conventions
- Runner handles all mechanical file operations — never create task folders manually
- AGENTS.md is shared reviewer constitution — loaded on demand, not every turn
- All reviewer output saved as artifacts — raw + normalized reviews

For full project architecture details, see `docs/project-context.md` if present.

<!-- PRIMECOUNCIL:START - Do not edit this section manually -->
## PrimeCouncil

Before orchestration decisions, read `primecouncil/orch-state.json`.
If missing, default to `{"orch": "off", "default_mode": "manual"}`.
`/prime-orch` is the canonical activation path; natural language commands are aliases.

`ORCH ON/OFF`, `MODE MANUAL/STANDARD/DEEP` → update `orch-state.json`.
`GO STANDARD/DEEP/DIRECT` → task-scoped only, do NOT update `orch-state.json`.

If `orch` is `"on"`, or the user turns orchestration on, or issues a `GO` command:
read `primecouncil/ORCHESTRATION.md` using the Read tool and enter orchestration-aware mode.
`ORCH OFF` updates state and exits orchestration-aware mode — no contract loading needed.
Do NOT use @import — read on demand.

After `/compact` or session reset: re-read `orch-state.json`.
If `orch` is `"on"`, re-read `primecouncil/ORCHESTRATION.md`.

Do not load `AGENTS.md` on activation. Load only when entering reviewer/packetized steps.

Confirm activation visibly when orchestration becomes active.

If orchestration seems inactive when it should be active:
read `primecouncil/ORCHESTRATION.md` and continue in orchestration-aware mode.
<!-- PRIMECOUNCIL:END -->
