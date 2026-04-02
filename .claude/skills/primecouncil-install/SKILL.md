---
name: primecouncil-install
description: Install or update the PrimeCouncil multi-LLM orchestration framework in the current repository. Use this skill when the user says "install primecouncil", "set up orchestration", "add primecouncil to this repo", or when the primecouncil/ folder exists but CLAUDE.md is missing the orchestration contract.
---

# PrimeCouncil Install

Set up the PrimeCouncil orchestration kit in the current repository.

## Step 1 — Check for existing CLAUDE.md

If a CLAUDE.md already exists:
1. Read it and note any useful project-specific content (stack, conventions, commands, architecture).
2. Ask the user: "I found an existing CLAUDE.md with project content. I'll preserve it and merge into PrimeCouncil's format. OK?"
3. Wait for confirmation.

If no CLAUDE.md exists, proceed directly.

## Step 2 — Write CLAUDE.md

Write the standard 2-part CLAUDE.md:
- **Part 1 (orchestration contract):** Use the fixed PrimeCouncil orchestration contract. Never modify Part 1 after install.
- **Part 2 (active project context):** Fill from any preserved content from Step 1. If none, leave `[Fill in]` placeholders.

The orchestration contract template is in `primecouncil/docs/` — read it from there if available, or use the standard contract from references/claude-contract-template.md in this skill.

## Step 3 — Verify kit structure

Ensure these exist, create any missing:

```
primecouncil/
  runner.py
  scripts/
    review-codex.sh
    review-gemini.sh
  packets/
    templates/
      first-pass-review.md
      synthesis-review.md
      implementation-review.md
  docs/
    protocol-detail.md
    project-context.md
    packet-spec.md
    runs-spec.md
  runs/
```

Also ensure at repo root:
- `AGENTS.md` — shared reviewer constitution
- `GEMINI.md` — thin Gemini wrapper

If the `primecouncil/` folder doesn't exist, tell the user to copy the PrimeCouncil kit into the repo first.

## Step 4 — Fill project context

If Part 2 has `[Fill in]` markers:
1. Ask the user to briefly describe: project purpose, stack, key conventions.
2. Fill Part 2 (keep under 30 lines).
3. Write detailed version to `primecouncil/docs/project-context.md`.

## Step 5 — Confirm

Tell the user:
- PrimeCouncil is installed.
- Say `ORCH ON` to activate orchestration.
- Chat normally for direct work.
- Update project context anytime by saying "update project context."

## Rules
- **Never modify Part 1** of CLAUDE.md after install.
- **Always ask before overwriting** an existing CLAUDE.md.
- **Keep it simple.** Ask the user for project details, don't auto-scan the repo.