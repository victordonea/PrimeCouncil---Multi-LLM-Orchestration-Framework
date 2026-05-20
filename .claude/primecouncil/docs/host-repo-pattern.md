# PrimeCouncil Host-Repo Pattern

How PrimeCouncil integrates with any repository.

---

## Core Principle

PrimeCouncil is a **guest** in your repo, not the owner. The root `CLAUDE.md` belongs to the project. PrimeCouncil adds a small managed block at the bottom.

## The Two-File Pattern

Every host repo uses two files for project knowledge:

1. **`CLAUDE.md`** — the **behavior file** (50-200 lines). Tells Claude how to behave in this repo. Contains project identity, stack, key boundaries, rules, and the managed PrimeCouncil tripwire block. Always loaded.

2. **`docs/project-context.md`** — the **reference file** (optional, any length). Gives Claude and the user a comprehensive understanding of the project. Should be structured, detailed, and reusable. Created during install if the user wants it.

Project context belongs to the **host repo** (`docs/project-context.md`), not to the PrimeCouncil kit. PrimeCouncil does not own or manage this file — it only helps generate it during install.

## What root CLAUDE.md looks like

```
[Your project content — identity, stack, conventions, rules]
[References to detailed docs if needed]
[30-50 lines, whatever the project requires]

<!-- PRIMECOUNCIL:START - Do not edit this section manually -->
[Managed tripwire block]
[Handles: orch-state.json read/write, command recognition, contract loading]
<!-- PRIMECOUNCIL:END -->
```

The project content above the markers is **yours**. Write whatever the project needs. The installer never touches it.

The block between the markers is **managed by PrimeCouncil**. The installer inserts it on first install and updates it on subsequent installs. Do not edit it by hand.

## What goes in the project content (above the markers)

1. **What the project is** — name, purpose, 2-3 lines
2. **Stack** — technologies, services, key tools, 3-5 lines
3. **Key conventions and rules** — coding standards, naming, constraints, 5-10 lines
4. **References to detailed docs** — point to longer docs that Claude should read on demand, 2-3 lines
5. **Directory boundaries** — if the repo has multiple technical domains, state which conventions apply where

Keep it under 50 lines. If you need more detail, put it in separate docs and reference them.

## Root CLAUDE.md rules

The root `CLAUDE.md` **should:**
- Describe what the repo is
- Describe the stack and current status
- Point to important docs
- Define any major project-level boundaries
- Contain the small managed PrimeCouncil tripwire block

The root `CLAUDE.md` should **NOT:**
- Embed the full PrimeCouncil orchestration contract
- Become a giant instruction dump
- Contain long domain-specific manuals (those live in docs or scoped rules)
- Be rewritten wholesale by the installer

## What goes in the tripwire block (between the markers)

The installer manages this. It contains:

- Instruction to read `.claude/primecouncil/orch-state.json` before any orchestration decision
- `/prime-orch` is the canonical activation/state-control path; natural language commands (`ORCH ON`, `MODE STANDARD`, etc.) are aliases to the same state model
- Write rules that update `orch-state.json`:
  - `ORCH ON`, `MODE MANUAL/STANDARD/DEEP` → update persistent state in orch-state.json
  - `ORCH OFF` → update state and exit orchestration-aware mode; no contract loading needed
  - `GO STANDARD/DEEP/DIRECT` → do **not** update persistent state; only trigger contract loading for the current task
- Instruction to read `.claude/primecouncil/ORCHESTRATION.md` (via Read tool, NOT @import) when orchestration is active or being activated
- Post-/compact recovery: re-read state, re-load contract if active
- Visible confirmation on activation
- Manual fallback: if orchestration appears inactive when it should be active, explicitly read `.claude/primecouncil/ORCHESTRATION.md` and continue in orchestration-aware mode

The managed block must **NOT:**
- Use `@import` for `.claude/primecouncil/ORCHESTRATION.md` — @imports are expanded at launch, which would load ~180 lines every session and defeat on-demand loading
- Auto-load the full contract every session
- Auto-load `AGENTS.md` on activation

## AGENTS.md loading rule

`AGENTS.md` must be lazy-loaded **only** when actually entering reviewer/packetized steps:
- Building packets
- Invoking reviewers
- Performing synthesis

It should **not** be loaded merely because orchestration was turned on. This avoids wasting tokens during the planning/discussion phase and prevents reviewer persona bleed into non-review work.

## What lives where

| Content | Location | Loaded when |
|---------|----------|-------------|
| Project identity, stack, rules | Root `CLAUDE.md` | Every session (always) |
| PrimeCouncil tripwire | Root `CLAUDE.md` (managed block) | Every session (always, but small) |
| Full orchestration contract | `.claude/primecouncil/ORCHESTRATION.md` | On demand (when orch is active) |
| Reviewer rules | `.claude/primecouncil/AGENTS.md` | On demand (during reviewer/packetized steps only) |
| Gemini-specific rules | `.claude/primecouncil/GEMINI.md` | On demand (during Gemini reviewer invocation) |
| Orchestration state | `.claude/primecouncil/orch-state.json` | Checked before orchestration decisions |
| Detailed project context | `docs/project-context.md` (optional) | On demand, if present |
| Domain-specific rules (e.g. n8n) | `docs/` or `.claude/rules/` | On demand or path-scoped |

## Installer behavior

The installer must be marker-based and idempotent.

That means:
- It must never overwrite the whole root `CLAUDE.md`
- It must insert or update only the managed PrimeCouncil block
- It must preserve all existing project-specific content
- It must create or update `.claude/primecouncil/ORCHESTRATION.md`
- It must avoid duplicate tripwire blocks on repeated installs
- It must use `<!-- PRIMECOUNCIL:START -->` / `<!-- PRIMECOUNCIL:END -->` markers to locate its section

## Setup for any new repo

1. Create the repo
2. Write your project-first `CLAUDE.md` (just the project content — no PrimeCouncil block)
3. Copy the `.claude/primecouncil/` folder into `.claude/primecouncil/`
4. Copy `AGENTS.md` and `GEMINI.md` into `.claude/primecouncil/`
5. Run `/prime-install`
6. The installer adds the managed tripwire block to your existing `CLAUDE.md`
7. Say `ORCH ON` to activate when needed

## Rules

- **Never** put the full orchestration contract in root `CLAUDE.md`. That's what ORCHESTRATION.md is for.
- **Never** @import ORCHESTRATION.md from CLAUDE.md. It defeats on-demand loading.
- **Never** manually edit the managed block. Let the installer handle it.
- **Keep project content and PrimeCouncil content separate.** Project above the markers, PrimeCouncil between the markers.
- **Each repo gets its own project content.** The tripwire is the same everywhere; the project section is unique.
- **Domain-specific rules live outside root CLAUDE.md.** Use `docs/`, `.claude/rules/`, or subdirectory `CLAUDE.md` files.

## Goal

The result should be:
- Repo identity stays clear
- PrimeCouncil remains fully available
- Orchestration activates only when needed
- Token budget is respected — heavy rules load on demand, not permanently
- The same PrimeCouncil kit can be reused across many different repos
