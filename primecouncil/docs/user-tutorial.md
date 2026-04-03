# PrimeCouncil — Quick Reference Card

---

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
| `/primecouncil-install` | Setting up a new repo | Creates CLAUDE.md, ensures kit structure, fills project context |
| `/prime-save` | After completing a task, or before `/clear` | Saves task-summary and/or updates project-progress (may save one, both, or neither depending on context) |
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
| `CLAUDE.md` | Orchestration contract + project context | Every turn (always) |
| `AGENTS.md` | Shared reviewer constitution | When orchestration step runs |
| `GEMINI.md` | Gemini-specific instructions | When Gemini CLI is invoked |
| `primecouncil/docs/project-context.md` | Deep project details | On demand for complex tasks |
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


----------------------
## Your modes explained with scenarios:

ORCH OFF = Claude is just Claude. No orchestration awareness at all. You chat, Claude answers. No modes, no reviewers, no tasks. Like talking to vanilla Claude.

ORCH ON + MODE MANUAL = Claude is orchestration-aware. When you give a substantial task, Claude says "This looks like it deserves STANDARD mode. Want to proceed?" But it WAITS for you to pick. It never auto-selects a mode. You decide every time.

ORCH ON + MODE STANDARD = Claude is orchestration-aware AND defaults to STANDARD. When you give a substantial task, Claude says "Starting this in STANDARD mode" and goes. You don't have to pick each time. You can still override with GO DEEP or GO DIRECT on any specific task.

ORCH ON + MODE DEEP = Same, but defaults to DEEP for every substantial task.

The GO commands = One-shot overrides. You're in MODE STANDARD but you say GO DEEP for one particularly complex task. That task runs in DEEP. The next task goes back to your default (STANDARD).

Practical example:


You:    ORCH ON                    → Claude is aware, MODE defaults to MANUAL
You:    /orch standard             → default mode is now STANDARD
You:    "Build me a login system"  → Claude activates STANDARD automatically
You:    "GO DEEP"                  → this specific task switches to DEEP
        (task finishes)
You:    "Add a logout button"      → back to STANDARD (the default)
You:    /orch off                  → Claude goes back to vanilla mode