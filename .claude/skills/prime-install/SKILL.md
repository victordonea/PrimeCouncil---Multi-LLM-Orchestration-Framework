---
name: prime-install
description: Install or update the PrimeCouncil multi-LLM orchestration framework in the current repository. Use this skill when the user says "install primecouncil", "set up orchestration", "add primecouncil to this repo", or when the .claude/primecouncil/ folder exists but CLAUDE.md is missing the PrimeCouncil managed block.
---

# PrimeCouncil Install

Set up the PrimeCouncil orchestration kit in the current repository.
PrimeCouncil is a **guest** — it adds a small managed block to your CLAUDE.md, not a full contract.
See `.claude/primecouncil/docs/host-repo-pattern.md` for the full integration pattern.

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

Before orchestration decisions, read `.claude/primecouncil/orch-state.json`.
If missing, default to `{"orch": "off", "default_mode": "manual"}`.
`/prime-orch` is the canonical activation path; natural language commands are aliases.

`ORCH ON/OFF`, `MODE MANUAL/STANDARD/DEEP` → update `orch-state.json`.
`GO STANDARD/DEEP/DIRECT` → task-scoped only, do NOT update `orch-state.json`.

If `orch` is `"on"`, or the user turns orchestration on, or issues a `GO` command:
read `.claude/primecouncil/ORCHESTRATION.md` using the Read tool and enter orchestration-aware mode.
`ORCH OFF` updates state and exits orchestration-aware mode — no contract loading needed.
Do NOT use @import — read on demand.

After `/compact` or session reset: re-read `orch-state.json`.
If `orch` is `"on"`, re-read `.claude/primecouncil/ORCHESTRATION.md`.

Do not load `AGENTS.md` on activation. Load only when entering reviewer/packetized steps.

Confirm activation visibly when orchestration becomes active.

If orchestration seems inactive when it should be active:
read `.claude/primecouncil/ORCHESTRATION.md` and continue in orchestration-aware mode.
<!-- PRIMECOUNCIL:END -->
```

## Step 3 — Create default orch-state.json

If `.claude/primecouncil/orch-state.json` does not exist, create it:
```json
{
  "orch": "off",
  "default_mode": "manual"
}
```

## Step 5 — Verify kit structure

Ensure these exist, create any missing:

```
.claude/primecouncil/
  ORCHESTRATION.md
  runner.py
  config.json
  orch-state.json
  AGENTS.md
  GEMINI.md
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

If the `.claude/primecouncil/` folder doesn't exist, tell the user to copy the PrimeCouncil kit into the repo first.

## Step 6 — Project context (optional)

Project context lives at `docs/project-context.md` in the host repo, NOT inside `.claude/primecouncil/docs/`.
It is optional — the user decides whether to create it.

**6a. If `docs/project-context.md` already exists**, present numbered options in chat:
Header: "Project context" | Options:
- **Keep existing** — don't touch it
- **Refresh** — update with a new scan while preserving structure
- **Overwrite** — replace entirely with fresh generation

If "Keep existing" → skip to Step 7.

**6b. If no file exists (or user chose Refresh/Overwrite)**, present numbered options in chat:
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
- Scan the repo broadly, but **exclude**: `.git/`, `node_modules/`, `dist/`, `build/`, `__pycache__/`, `.next/`, `.claude/primecouncil/runs/`, lock files, binaries, media, generated/cache folders
- Focus on source files, docs, and config

**6e. Generate** `docs/project-context.md` using the template from `references/project-context-template.md`. The generated file should be comprehensive and high-value — not a lightweight placeholder.

**6f. If the installer created a new CLAUDE.md** (Step 1, "no CLAUDE.md exists" path):
- Ask the user to briefly describe: project purpose, stack, key conventions
- Write project content above the PrimeCouncil markers (keep under 50 lines)
- If CLAUDE.md already existed with project content, do NOT modify it

## Step 7 — Confirm and show quickstart

Present a clear quickstart message to the user:

```
✅ PrimeCouncil is installed!

QUICK START:
1. Turn on orchestration:  /prime-orch on
2. Set your default mode:  /prime-orch standard  (or deep, or manual)
3. Describe a task normally — Claude will take it from there

HOW A TASK WORKS:
You describe what you need — a decision, a design, a feature, a fix.
Claude recognizes it as a task and kicks off the orchestration:
- Claude writes its own first-pass analysis
- Codex (ChatGPT) and Gemini review independently — they can't see Claude's answer
- Claude synthesizes all three perspectives into one picture
- You get a checkpoint to add your input or continue
- A second round of review happens with the combined view
- Claude produces the final recommendation and executes
- After execution, you choose: accept & close, send to reviewers, or rethink

KEY COMMANDS:
- /prime-orch on/off/standard/deep/manual/status — control orchestration
- /prime-save — save progress before /clear or restart
- /prime-resume — pick up where you left off
- ORCH ON, GO STANDARD, GO DEEP — natural language also works

📖 Full guide: .claude/primecouncil/docs/user-tutorial.md
```

## Rules
- **Never overwrite the whole CLAUDE.md.** Only insert/update the managed block.
- **Never recreate the old Part 1 / Part 2 structure.** That format is deprecated.
- **Use markers** (`<!-- PRIMECOUNCIL:START -->` / `<!-- PRIMECOUNCIL:END -->`) for idempotent block management.
- **Preserve all existing project content** outside the markers.
- **Always ask before creating a new CLAUDE.md** if none exists.
- **Keep it simple.** Ask the user for project details, don't auto-scan the repo.
- **Maintenance rule:** Whenever `.claude/primecouncil/ORCHESTRATION.md` changes, sync `references/orchestration-template.md`.
