---
name: prime-save
description: Save PrimeCouncil orchestration context (task-summary.md and/or project-progress.md) before /clear or after meaningful task completion. Use ONLY for PrimeCouncil continuity saving, NOT for generic file-writing requests. Trigger when the user says "prime save", "save task summary", "save project progress", "save context before clear", or when Claude recommends saving before clearing/restarting. If the user says "save" without PrimeCouncil context, do NOT use this skill — ask which type of save they mean.
---

# /prime-save — Save Context

Save task-level and/or project-level context so nothing useful is lost on session restart.

## Step 1 — Assess what needs saving

Determine the current situation:

**Is there an active unfinished task?**
- Check: `python primecouncil/runner.py list`
- If an active task exists with unsaved or outdated context → task-summary needed

**Was there meaningful project-level progress?**
- A task was completed
- A durable project decision was made
- Priorities or blockers changed
- Direction shifted

Present save options via AskUserQuestion.
Header: "Save" | Options:
- **Save task summary** — Resume point for this task
- **Save project progress** — Project-level story update
- **Save both**
- **Skip** — Nothing to save

Do not present the chooser if the user already specified what to save.

## Step 2 — Save task summary (if needed)

Use the template structure from `primecouncil/packets/templates/task-summary.md`.

Write it with:
```
python primecouncil/runner.py save --task-id TASK_ID --filename task-summary.md --content "..."
```

**Content rules:**
- Task metadata: id, label, mode, status
- Current objective: what the task is trying to achieve NOW (1-3 lines)
- What was decided: only decisions that matter for continuation (max 5 bullets)
- What was done: meaningful completed work only (max 5 bullets)
- Open items: unresolved questions, blockers, pending checks (max 5 bullets)
- Resume starting point: the exact next action (1-3 lines)
- Relevant artifacts: file paths worth reading first (max 5)

**Anti-redundancy:** Only include what helps an LLM continue THIS task. Do not include project-level direction or broad context that belongs in project-progress.md.

## Step 3 — Update project progress (if needed)

Read the current `primecouncil/docs/project-progress.md`.

**Smart patching — only add what's new:**
1. Read current file content
2. Compare against what just happened in the session
3. Add only: new milestones, new durable decisions, changed priorities, new/removed blockers
4. Skip the update entirely if nothing project-level changed
5. Update "Current state" section if direction or priorities shifted
6. Update "Next priorities" section if they changed
7. Append new entries to "Recent decisions and progress" with today's date

**Entry format for the log:**
```
### YYYY-MM-DD — [short label]
[1-3 lines: what happened and why it matters at the project level]
```

**Compression — apply when log exceeds 10 entries:**
1. Count entries in the recent log section
2. If >10 entries:
   - Keep the newest 5-7 entries as-is
   - Compress older entries into one "Earlier progress" block with date range
   - Example: `### Earlier progress (March 28 – April 5)`
   - Only compress entries that are completed and no longer individually needed
   - Do NOT compress current blockers, active priorities, or recent decisions still shaping work
3. Rewrite the file cleanly after compression

**Anti-redundancy:** Only include things that changed the project-level story. Do not repeat task-local details, round debates, or debugging notes.

## Step 4 — Confirm

Tell the user what was saved:
- Which files were written/updated
- Brief summary of what was captured

## Rules
- Always ask the user before writing. Never auto-save.
- Keep task-summary.md focused on task resumption only.
- Keep project-progress.md focused on project trajectory only.
- If nothing meaningful happened, say so and skip the save.