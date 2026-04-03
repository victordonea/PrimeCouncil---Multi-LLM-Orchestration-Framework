# PrimeCouncil — Context Transfer Briefing

This document transfers the full development context from the initial build phase (conducted in Claude web chat + ChatGPT collaboration) to Claude Code for continued development.

**Read this file completely before doing any work. Then you can delete it — it's a one-time briefing, not a permanent file.**

---

## What PrimeCouncil is

A multi-LLM orchestration framework where Claude (you) acts as orchestrator/synthesizer/executor, Codex CLI and Gemini CLI act as independent reviewers, and the human is the strategic supervisor. The system enforces first-pass independence (each AI reviews independently before seeing others' answers), preserves material disagreements, and saves everything as auditable artifacts.

## How we got here

The system was designed collaboratively across multiple phases:
- **Phase 0–1:** Protocol design + proof of life. Done in ChatGPT conversations.
- **Phase 2:** Optimization pass — CLAUDE.md compressed from ~250 to ~180 lines, AGENTS.md from ~280 to ~93 lines, token/context hygiene rules applied throughout.
- **Phase 3:** Operationalization — Python runner built, skills created, save/resume system designed.
- **Current:** Steps 1–20 of 24 are complete. Steps 21–24 remain.

## ChatGPT's role in this project

Two ChatGPT instances contributed:
- **ChatGPT v0:** Deep architectural context holder. Designed the original protocol, reviewed all optimization decisions. Now retired (context too long).
- **ChatGPT v1:** Active reviewer. Reviews every major deliverable before it ships. Provides practical flags on runner bugs, template issues, naming consistency.

**Working model going forward:** Claude (you) builds. ChatGPT v1 reviews high-stakes deliverables. The human supervises and makes final calls. This is PrimeCouncil's own model applied to building PrimeCouncil.

## Locked design decisions (do NOT reopen)

These were debated, validated by multiple LLMs, and locked:

- CLAUDE.md is 2-part: orchestration contract (Part 1, never modified after install) + project context (Part 2, filled per project)
- AGENTS.md ~80–100 lines, reviewer constitution — stays at repo root, loaded by reviewer CLIs
- No @AGENTS.md import in CLAUDE.md — routing instruction instead (on-demand loading)
- 4 files in docs/, capped, single purpose each
- Normalized reviewer outputs via ===REVIEW START=== marker — scripts auto-extract, Claude never reads raw dumps
- Packet compactness with hard section limits (objective 3 lines, constraints 10 bullets, questions 3-5)
- Same packet body for both reviewers, runner inserts focus line automatically
- Python runner handles ALL mechanical plumbing — Claude never creates folders/packets manually
- PrimeCouncil is a portable kit dropped into any project repo
- /primecouncil-install is a skill (not a command) with canonical templates in references/
- Session hygiene: recommend only, never auto-execute (/clear, /compact, etc.)
- task-summary.md = resume one specific task | project-progress.md = project story across tasks
- Two context skills: /prime-save (write) and /prime-resume (read)
- Smart compression: project-progress >10 entries → compress oldest into summary block, keep 5-7 newest
- DEEP mode uses current-state.md (overwritten each round) for flat token cost
- Never send secrets/credentials/client-sensitive data in packets

## Remaining roadmap (Steps 21–24)

### Step 21 — Config file for paths and models
Create `primecouncil/config.md` or `config.json`. Centralizes: Codex model name, Gemini model, reviewer script paths, runs directory path, timeout values. Scripts and runner read from this instead of hardcoding.
**Review:** Send to ChatGPT v1.

### Step 22 — Failed run recovery
Runner detects partial state: packet exists but no review output. Status flags incomplete rounds. Support re-running a specific round without re-initializing. Runner-side only, zero token impact.
**Review:** Send to ChatGPT v1.

### Step 23 — Anti-groupthink guardrails
In round 2+ synthesis packets: reviewers must state what they CHANGED their mind on and why. Must flag if agreeing only because synthesis was persuasive. Claude notes when all three agree suspiciously fast. ~2 lines added to templates.
**Review:** Send to ChatGPT v1.

### Step 24 — Structured checkpoints in orchestration
At human checkpoints during STANDARD/DEEP, Claude presents structured choices: Continue / Add preference / Add directive / Pause / Approve DEEP escalation / Close task. Add checkpoint format rules to CLAUDE.md.
**Review:** Send to ChatGPT v1.

### After Step 24 — Step 16: First real task
Use PrimeCouncil on an actual project task end-to-end. This is the real validation.

## Important context about the runner

- Located at `primecouncil/runner.py`
- Commands: init, save, review, new-round, status, list
- review supports: --round N, --impl, --codex-only, --gemini-only
- save supports: --round N, --impl
- All output is JSON
- Validates task-id exists before operations
- Cleans stale files on rerun (including skipped reviewer artifacts)
- Slug sanitization: only a-z, 0-9, hyphens, with empty fallback

## Important context about the skills

Three skills in `.claude/skills/`:
- `primecouncil-install/` — with references/ containing canonical templates for CLAUDE.md Part 1, AGENTS.md, GEMINI.md
- `prime-save/` — context saving with smart compression
- `prime-resume/` — context loading and restart briefing

## Important maintenance rule

**Whenever CLAUDE.md Part 1 changes, immediately re-sync `.claude/skills/primecouncil-install/references/claude-contract-template.md`.** This template is the single canonical source for the install skill. Drift here means new installs get an outdated contract.

## Token/context philosophy

The entire system was designed around these principles:
- CLAUDE.md is read every turn — keep it lean
- AGENTS.md is loaded on-demand by Claude, but always-loaded by reviewer CLIs (one-shot cost, not per-turn)
- Reviewer raw outputs are never re-consumed — scripts extract clean reviews via ===REVIEW START=== marker
- DEEP mode uses current-state.md to avoid accumulating synthesis files
- Packets are decision briefs, not conversation exports
- Session hygiene is the user's call — Claude recommends, never auto-executes
- /prime-save and /prime-resume handle cross-session continuity without bloating context

## What to do with this file

After reading it fully:
1. Confirm you understand the current state
2. Review the roadmap file for step status
3. Continue with Step 21 or whichever step the user requests
4. Delete this file — it's transfer context, not a permanent artifact
