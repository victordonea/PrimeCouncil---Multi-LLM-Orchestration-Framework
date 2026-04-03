---
name: prime-resume
description: Resume PrimeCouncil orchestration context after /clear or in a new session. Use ONLY to reconstruct PrimeCouncil task and project state, NOT for generic session continuation. Trigger when the user says "prime resume", "where were we on the task", "pick up the orchestration", or "resume primecouncil", or when the user explicitly wants to continue previous PrimeCouncil work. If the user says "resume" without PrimeCouncil context, do NOT use this skill.
---

# /prime-resume — Resume Context

Reconstruct working context from saved artifacts after a session restart or /clear.

## Step 1 — Discover state

Run both of these:

**Project progress:**
Read `primecouncil/docs/project-progress.md` if it exists.

**Active tasks:**
Run `python primecouncil/runner.py list`

From the list output, identify:
- Tasks with status "active" or "paused"
- Tasks with `has_summary: true`
- Most recently modified task (by `last_modified` date)

## Step 2 — Load relevant summaries

For each active task that has a summary:
Read `primecouncil/runs/TASK_ID/task-summary.md`

If there are multiple active tasks, prioritize the most recently modified one.
Do not load more than 2 task summaries — if there are more, list them and ask the user which to focus on.

## Step 3 — Produce restart brief

Present one concise brief to the user with this structure:

**Project status:**
[2-4 lines from project-progress.md: current state + next priorities. If no project-progress.md exists, say so.]

**Active task(s):**
[For each active task with a summary:]
- Task: [task_id] — [label]
- Mode: [STANDARD/DEEP]
- Where we left off: [resume starting point from task-summary]
- Open items: [key unresolved items]

**Other tasks:** [list any other active tasks without summaries, if any]

**Recommended next action:**
[Based on the most recent task's resume starting point, suggest what to do next]

## Step 4 — Ask the user

After presenting the brief, ask:
- "Continue with [most recent task]?"
- "Switch to a different task?"
- "Start something new?"

## Rules
- Do NOT load raw reviewer outputs or round-by-round files. Only read task-summary.md and project-progress.md.
- Do NOT load more than 2 task summaries without asking the user first.
- Keep the restart brief under 30 lines. The goal is fast orientation, not full history replay.
- If no project-progress.md exists and no active tasks have summaries, tell the user: "No saved context found. What would you like to work on?"