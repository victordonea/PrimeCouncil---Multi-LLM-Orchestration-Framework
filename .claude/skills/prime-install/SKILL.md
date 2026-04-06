---
name: prime-install
description: Install or update the PrimeCouncil multi-LLM orchestration framework in the current repository. Use this skill when the user says "install primecouncil", "set up orchestration", "add primecouncil to this repo", or when the primecouncil/ folder exists but CLAUDE.md is missing the PrimeCouncil managed block.
---

# PrimeCouncil Install

Set up the PrimeCouncil orchestration kit in the current repository.
PrimeCouncil is a **guest** — it adds a small managed block to your CLAUDE.md, not a full contract.
See `primecouncil/docs/host-repo-pattern.md` for the full integration pattern.

## Step 1 — Check for existing CLAUDE.md

Read the root `CLAUDE.md` (the file at `./CLAUDE.md`, not `./.claude/CLAUDE.md`).

**If CLAUDE.md exists:**
1. Look for `<!-- PRIMECOUNCIL:START -->` and `<!-- PRIMECOUNCIL:END -->` markers.
   - If markers found: this is an **update**. Replace only the content between the markers with the current tripwire block. Do not touch anything outside the markers.
   - If no markers found: this is a **first install**. Append the managed tripwire block at the end of the file. Do not modify existing project content.
2. Tell the user what you're doing: "Found existing CLAUDE.md. Adding/updating PrimeCouncil managed block."

**If no CLAUDE.md exists:**
1. Create a minimal project-first template with placeholders + the managed tripwire block at the end.
2. Ask the user to fill in the project details.

## Step 2 — Write the managed tripwire block

The generic PrimeCouncil tripwire block to insert/update (from the host-repo pattern, not any project-specific example):

```markdown
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
```

## Step 3 — Create or update ORCHESTRATION.md

Write the full orchestration contract to `primecouncil/ORCHESTRATION.md`.
Use the template from `references/orchestration-template.md` in this skill.

If `primecouncil/ORCHESTRATION.md` already exists, overwrite it with the latest template (the contract is canonical — updates are safe).

## Step 4 — Create default orch-state.json

If `primecouncil/orch-state.json` does not exist, create it:
```json
{
  "orch": "off",
  "default_mode": "manual"
}
```

## Step 5 — Verify kit structure

Ensure these exist, create any missing:

```
primecouncil/
  ORCHESTRATION.md
  runner.py
  config.json
  orch-state.json
  scripts/
    review-codex.sh
    review-gemini.sh
    statusline.sh
  packets/
    templates/
      first-pass-review.md
      synthesis-review.md
      implementation-review.md
      final-recommendation.md
      task-summary.md
  docs/
    protocol-detail.md
    packet-spec.md
    runs-spec.md
    host-repo-pattern.md
    user-tutorial.md
  runs/
```

Also ensure at repo root:
- `AGENTS.md` — shared reviewer constitution
- `GEMINI.md` — thin Gemini wrapper

If the `primecouncil/` folder doesn't exist, tell the user to copy the PrimeCouncil kit into the repo first.

## Step 6 — Project context (optional)

Project context lives at `docs/project-context.md` in the host repo, NOT inside `primecouncil/docs/`.
It is optional — the user decides whether to create it.

**6a. If `docs/project-context.md` already exists**, present via AskUserQuestion:
Header: "Project context" | Options:
- **Keep existing** — don't touch it
- **Refresh** — update with a new scan while preserving structure
- **Overwrite** — replace entirely with fresh generation

If "Keep existing" → skip to Step 7.

**6b. If no file exists (or user chose Refresh/Overwrite)**, present via AskUserQuestion:
Header: "Project context" | Options:
- **Selective scan** — scan important files, follow references recursively
- **Full scan** — scan the whole repo (excluding generated/irrelevant dirs)
- **Skip** — no project context file

If "Skip" → continue to Step 7.

**6c. Selective scan behavior:**
- Start with anchor files: README.md, root docs, architecture/spec files, config/build files, existing CLAUDE.md, major directories referenced by docs
- Recursively follow referenced files only when they materially improve understanding
- Do not blindly read the entire repo

**6d. Full scan behavior:**
- Scan the repo broadly, but **exclude**: `.git/`, `node_modules/`, `dist/`, `build/`, `__pycache__/`, `.next/`, `primecouncil/runs/`, lock files, binaries, media, generated/cache folders
- Focus on source files, docs, and config

**6e. Generate** `docs/project-context.md` using the template from `references/project-context-template.md`. The generated file should be comprehensive and high-value — not a lightweight placeholder.

**6f. If the installer created a new CLAUDE.md** (Step 1, "no CLAUDE.md exists" path):
- Ask the user to briefly describe: project purpose, stack, key conventions
- Write project content above the PrimeCouncil markers (keep under 50 lines)
- If CLAUDE.md already existed with project content, do NOT modify it

## Step 7 — Confirm

Tell the user:
- PrimeCouncil is installed.
- Say `ORCH ON` or `/prime-orch on` to activate orchestration.
- Chat normally for direct work.
- The full orchestration contract is in `primecouncil/ORCHESTRATION.md` (loaded on demand).
- Update project context anytime by saying "update project context."

## Rules
- **Never overwrite the whole CLAUDE.md.** Only insert/update the managed block.
- **Never recreate the old Part 1 / Part 2 structure.** That format is deprecated.
- **Use markers** (`<!-- PRIMECOUNCIL:START -->` / `<!-- PRIMECOUNCIL:END -->`) for idempotent block management.
- **Preserve all existing project content** outside the markers.
- **Always ask before creating a new CLAUDE.md** if none exists.
- **Keep it simple.** Ask the user for project details, don't auto-scan the repo.
- **Maintenance rule:** Whenever `primecouncil/ORCHESTRATION.md` changes, sync `references/orchestration-template.md`.
