# PrimeCouncil — User Guide

---

# Part 1 — Getting Started

## What is PrimeCouncil?

PrimeCouncil makes 3 AI models work together on your tasks instead of just one. **Claude** (your main assistant) leads the work. **Codex** (ChatGPT) and **Gemini** independently review Claude's ideas. They debate, disagree, and converge — and you get better results than any single AI could produce.

You stay in control. You choose when to activate it, what mode to use, and you make the final calls.

## Prerequisites

Before installing, make sure you have:

1. **Claude Code** — working in VS Code (you're probably already here)
2. **Codex CLI** — OpenAI's command-line tool for ChatGPT reviews
   <!-- Install: npm install -g @openai/codex. Auth: codex auth login -->
3. **Gemini CLI** — Google's command-line tool for Gemini reviews
   <!-- Install: npm install -g @google/gemini-cli. Auth: gemini (then /auth in interactive mode) -->
4. **Python 3** — needed by the runner
   <!-- Most systems have this. Test: python3 --version -->

Don't worry if you're not sure — PrimeCouncil will tell you if something's missing when you first use it.

## Installation (5 minutes)

**Step 1: Copy the PrimeCouncil kit into your project**

Copy these into your project's root folder:
- The `primecouncil/` folder (the whole thing)
- `AGENTS.md`
- `GEMINI.md`
- The `.claude/skills/` folder (contains the PrimeCouncil skills)
- `.claude/settings.json` (status line config)
- `.gitignore` (so personal state files aren't committed)

**Step 2: Run the installer**

Open your project in Claude Code and type:
```
/primecouncil-install
```

The installer will:
- Add a small PrimeCouncil block to your existing `CLAUDE.md` (or create one if you don't have one)
- Set up the orchestration contract
- Create default config files
- Ask you a few questions about your project

That's it. PrimeCouncil is installed.

**Step 3: Activate when you need it**

PrimeCouncil is **off by default**. Claude works normally until you turn it on.

To activate, type any of these:
```
/orch on          ← recommended way
ORCH ON           ← also works
/orch standard    ← turns on + defaults to STANDARD mode
```

You'll see a confirmation message and the status line at the bottom will show `ORCH:ON`.

## Your first orchestrated task

Once orchestration is on, just describe your task normally:

> "I need to decide whether to use Redis or PostgreSQL for the session store."

Claude will:
1. Recognize this as a real decision
2. Recommend a mode (STANDARD or DEEP)
3. Present you with clickable options to choose

Pick a mode, and the orchestration runs in two phases:

**Phase 1 — Planning & Review**
- Claude writes its own analysis first
- Codex and Gemini review independently (they can't see Claude's answer)
- Claude synthesizes all three perspectives
- You get a checkpoint to add input or continue
- A second round of review happens
- You get the final recommendation — the team's best answer

**Phase 2 — Implementation & Review**
- Claude executes the plan (writes code, edits files, runs commands)
- Claude presents a post-execution summary: what was done, what worked, what got complicated, what changed vs plan
- You get the final checkpoint:
  - **Accept & close task** — you're satisfied, task is marked complete
  - **Send implementation to reviewers** — Codex & Gemini review what was actually built (catches mistakes, missed requirements, better alternatives)
  - **Rethink this** — something's off, go back and revisit the approach

This gives you a **full closed loop** for every task: the team plans together, Claude builds, and you decide whether the result passes or needs another look.

## The three modes

| Mode | When to use | What happens |
|---|---|---|
| **DIRECT** | Simple questions, quick tasks | Claude answers alone, no reviewers |
| **STANDARD** | Most real tasks — decisions, designs, implementations | 1 independent round + 1 convergence round |
| **DEEP** | Critical architecture, high-risk, complex disagreements | Multiple rounds until the team converges |

## Quick commands cheat sheet

| What you want | What to say |
|---|---|
| Turn on orchestration | `/orch on` or `ORCH ON` |
| Turn it off | `/orch off` or `ORCH OFF` |
| Set default mode | `/orch standard` or `/orch deep` or `/orch manual` |
| Override mode for one task | `GO STANDARD` or `GO DEEP` or `GO DIRECT` |
| Check current state | `/orch status` |
| Save progress before clearing | `/prime-save` |
| Resume after a break | `/prime-resume` |

## How modes work together

**ORCH OFF** = Claude is just Claude. No orchestration. Like talking to vanilla Claude Code.

**ORCH ON + MANUAL** = Claude detects tasks and recommends a mode, but waits for you to pick.

**ORCH ON + STANDARD** = Claude defaults to STANDARD for substantial tasks. You can still say `GO DEEP` for a specific task.

**ORCH ON + DEEP** = Claude defaults to DEEP for everything substantial.

**GO commands** = One-shot overrides. They don't change your default — just that one task.

**Example session:**
```
You:    /orch standard             → orchestration on, defaults to STANDARD
You:    "Design the API endpoint"  → Claude activates STANDARD automatically
You:    "GO DEEP"                  → this specific task switches to DEEP
        (task finishes)
You:    "Add error handling"       → back to STANDARD (your default)
You:    /orch off                  → back to vanilla Claude
```

---

# Part 2 — Reference

## Orchestration commands (say these to Claude)

| Command | What happens |
|---|---|
| `ORCH ON` | Claude becomes orchestration-aware, recommends modes on substantial tasks |
| `ORCH OFF` | Back to normal Claude behavior |
| `GO STANDARD` | Start a STANDARD task (1 independent round + 1 convergence round) |
| `GO DEEP` | Start a DEEP task (multiple rounds until material convergence) |
| `GO DIRECT` | Claude handles it alone, no reviewers |
| `MODE MANUAL` | Claude recommends modes but waits for your confirmation |
| `MODE STANDARD` | Auto-default substantial tasks to STANDARD |
| `MODE DEEP` | Auto-default substantial tasks to DEEP |

Natural language works too: "go deep on this", "direct answer please", "let's do standard here."

---

## Skills (slash commands)

| Skill | When to use | What it does |
|---|---|---|
| `/primecouncil-install` | Setting up a new repo | Adds PrimeCouncil managed block to CLAUDE.md, creates orchestration contract |
| `/prime-save` | After completing a task, or before `/clear` | Saves task-summary and/or updates project-progress |
| `/prime-resume` | Starting a new session, after `/clear` | Loads saved context, shows where you left off, suggests next action |
| `/orch [on\|off\|standard\|deep\|manual\|status]` | Toggle orchestration state | Persists to `orch-state.json`, survives /compact and restarts |

---

## Runner commands (Claude calls these automatically)

Claude usually calls these automatically during orchestration. `status` and `list` are also useful for manual inspection.

| Command | Purpose |
|---|---|
| `runner.py init` | Create new task folder + metadata |
| `runner.py save` | Save any file to the right task/round location |
| `runner.py review` | Write packets + run both reviewers + save outputs |
| `runner.py review --codex-only` | Run only Codex (useful when Gemini has quota issues) |
| `runner.py review --gemini-only` | Run only Gemini |
| `runner.py review --impl` | Run implementation review |
| `runner.py new-round` | Create next round folder |
| `runner.py status` | Show files in each round |
| `runner.py complete` | Mark task as complete |
| `runner.py list` | List all tasks with status, mode, and summary info |

---

## The team

| Role | Who | Strengths |
|---|---|---|
| Orchestrator | Claude | Synthesis, execution, drives decisions |
| Analytical reviewer | Codex CLI | Depth, hidden assumptions, edge cases, structural flaws |
| Creative reviewer | Gemini CLI | UX, alternative framing, product thinking, fresh perspectives |
| Supervisor | You | Goals, preferences, final authority |

---

## How a STANDARD task flows

1. You describe a task → Claude recognizes it and recommends STANDARD
2. You say `GO STANDARD`
3. Claude writes its own first-pass answer
4. Claude sends clean packets to Codex and Gemini (without its own answer)
5. Both reviewers respond independently
6. Claude synthesizes all three views: agreements, disagreements, risks
7. **Checkpoint:** Claude asks if you want to add a preference, constraint, or direction
8. Claude sends the synthesis to both reviewers for a second pass
9. Claude produces the final integrated recommendation
10. Claude executes the chosen solution
11. Claude presents a **post-execution summary** — what was done, what worked, what got complicated, what changed vs plan
12. **Checkpoint:** Claude asks you to pick: **Accept & close task** (done!) / **Send implementation to reviewers** (Codex & Gemini check the work) / **Rethink this** (go back and revisit)
13. If you pick "Accept & close task" → task is marked complete. If "Send implementation to reviewers" → Codex and Gemini review the implementation. If "Rethink this" → back to discussion.

## How DEEP differs

Same start, but after the first synthesis, Claude keeps looping rounds until:
- No material disagreements remain
- No new meaningful insight appears
- One solution clearly dominates
- You decide to stop

Each round overwrites a `current-state.md` so token cost stays flat.

---

## Session hygiene (Claude recommends these, never auto-executes)

| Situation | What Claude recommends |
|---|---|
| Task completed | `/prime-save` to capture summary and progress |
| About to `/clear` or restart | `/prime-save` first if there's unsaved context |
| Topic switch | `/clear` (with `/prime-save` if needed) |
| Context at ~60% | `/compact` |
| After 2–3 DEEP loops | Save + restart |
| New session, want to continue | `/prime-resume` |

---

## Human feedback types

When Claude asks for your input at checkpoints:

| Type | Example | How Claude treats it |
|---|---|---|
| Soft preference | "I prefer the simpler version" | Important but not absolute |
| Hard directive | "Do not use Redis" | Binding unless impossible |
| No preference | "Continue without me" | Proceeds without bias |

---

## Key files

| File | Purpose | Loaded when |
|---|---|---|
| `CLAUDE.md` | Project identity + PrimeCouncil tripwire (managed block) | Always loaded as project context |
| `primecouncil/ORCHESTRATION.md` | Full orchestration contract | On demand (when orch is active) |
| `AGENTS.md` | Shared reviewer constitution | When orchestration step runs |
| `GEMINI.md` | Gemini-specific instructions | When Gemini CLI is invoked |
| `docs/project-context.md` | Deep project details (host repo, optional) | On demand if present |
| `primecouncil/docs/project-progress.md` | Project story across sessions | By `/prime-resume` and `/prime-save` |
| `primecouncil/docs/packet-spec.md` | Packet structure + brevity rules | When building packets |
| `primecouncil/docs/protocol-detail.md` | Full STANDARD/DEEP stage walkthrough | When orchestration step runs |
| `primecouncil/docs/runs-spec.md` | Run folder conventions | Reference only |
| `primecouncil/orch-state.json` | Persistent ORCH on/off + default mode | Before orchestration decisions (gitignored, per-user) |

---

## Per-task files (in `primecouncil/runs/TASK_ID/`)

| File | What it is |
|---|---|
| `task.md` | Task metadata (id, label, mode, status, objective) |
| `task-summary.md` | Resume handoff — written before session restart |
| `current-state.md` | DEEP mode only — latest state, overwritten each round |
| `round-NN/packet-*.md` | Packets sent to reviewers |
| `round-NN/*-output-raw.md` | Raw reviewer CLI output (audit only) |
| `round-NN/*-review.md` | Clean extracted reviews (Claude reads these) |
| `round-NN/synthesis.md` | Claude's synthesis |
| `round-NN/final-recommendation.md` | Final integrated decision |
| `implementation-review/` | Optional post-execution review |
