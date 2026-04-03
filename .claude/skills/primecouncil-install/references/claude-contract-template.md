# CLAUDE.md — PrimeCouncil Operating Contract

This repository uses PrimeCouncil, a multi-LLM orchestration framework.
Claude = orchestrator, synthesizer, executor. Codex + Gemini = reviewers. Human = supervisor.

---

# Part 1 — Orchestration Contract

## Instruction priority
1. Explicit user directives
2. Shared rules in AGENTS.md (loaded on demand — see routing below)
3. This file

## Routing — on-demand loading
Do NOT auto-import AGENTS.md every turn.
- Load `AGENTS.md` + relevant packet template only when actually executing a packetized step: building a packet, invoking reviewers, or performing synthesis. Not when merely discussing or recommending modes.
- In DIRECT mode or normal conversation: do not load shared docs.
- Before any orchestration decision (recommending a mode, activating a task, approving escalation, resuming after /compact), read `primecouncil/orch-state.json` for current state. If absent, default to orch: off, default_mode: manual.
- On-demand references: `primecouncil/docs/protocol-detail.md` (full stage walkthrough), `primecouncil/docs/project-context.md` (deep project details), `primecouncil/docs/packet-spec.md` (packet structure + brevity rules), `primecouncil/docs/runs-spec.md` (run folder conventions).

---

## Modes
**DIRECT** — Claude answers alone. For trivial, informational, or speed-priority tasks.
**STANDARD** — Default collaborative mode. One independent round, one combined round, user checkpoints.
**DEEP** — Heavy convergence. Multiple rounds until material convergence or user stops it.

Commands: `ORCH ON/OFF`, `MODE MANUAL/STANDARD/DEEP`, `GO STANDARD/DEEP/DIRECT`. Accept clear natural-language equivalents. Infer mode only when intent is clearly instructive.

ORCH OFF = behave normally. ORCH ON = orchestration-aware, recommend modes on substantial tasks. MODE MANUAL = recommend and wait. MODE STANDARD/DEEP = default to that mode unless overridden.

When the user says ORCH ON, ORCH OFF, MODE MANUAL, MODE STANDARD, or MODE DEEP, update `primecouncil/orch-state.json` to match. GO STANDARD / GO DEEP / GO DIRECT are task-scoped only and do not update persistent defaults.

---

## Task envelope

### A task starts when:
- User asks to build, fix, design, analyze, or implement something concrete
- User assigns a mode
- Claude confirms a task objective

### A task ends when:
- User says it is done
- Objective is complete and user moves on
- A clearly different objective begins (with user confirmation)

### Reporting
On task start: state task label, mode, orchestration active.
On task end: state task label, orchestration closed.
Never silently enter or exit a task envelope.

### Silent continuation
Once a task is approved under a mode, that mode persists for natural subtasks.
Only re-ask when: scope changes materially, work becomes a new task, user overrides.

---

## Mode recommendation
- **Talk normally** when: task is vague, exploratory, too small, or still being shaped.
- **Recommend STANDARD** when: task is concrete, meaningful, has real tradeoffs.
- **Recommend DEEP** when: architecture-critical, high-risk, ambiguous, or disagreement is visible.
- **DIRECT is enough** when: simple, informational, or user requests it.

Keep recommendations short: task label → recommended mode → short reason → ask user.

---

## Runner — mechanical automation
All file/folder operations during orchestration go through the runner. Do NOT manually create task folders, packet files, or round directories.

**Commands:**
- `python primecouncil/runner.py init --label "task name" --mode standard --objective "brief"` → creates task folder + round-01 + task.md. Returns JSON with task_id and paths.
- `python primecouncil/runner.py save --task-id TASK_ID --round N --filename NAME.md --content "..."` → saves any file to the right location.
- `python primecouncil/runner.py review --task-id TASK_ID --round N --content "packet body"` → writes both reviewer packets, runs both scripts, returns JSON with paths to clean reviews. For implementation review use `--impl` instead of `--round N`.
- `python primecouncil/runner.py new-round --task-id TASK_ID` → creates next round folder.
- `python primecouncil/runner.py status --task-id TASK_ID` → shows files in each round.
- `python primecouncil/runner.py complete --task-id TASK_ID` → marks task as complete, updates rounds count.

**When to call the runner:**
- On new task activation (STANDARD/DEEP): call `init`
- After writing first-pass: call `save` with `claude-first-pass.md`
- To invoke reviewers: call `review` with the packet body (runner handles file creation + script execution)
- After synthesis: call `save` with `synthesis.md`
- For implementation review: call `review --impl`
- On task completion: call `complete` (after post-execution summary and checkpoint)
- Never create run folders or packet files manually.

**Resuming after session reset / compaction:**
- Do NOT call `init` again. The task already exists.
- Call `status --task-id TASK_ID` to see where the task left off.
- Continue from the last completed step using `save`, `review`, or `new-round`.

**Packet body format:** Write packet content without a reviewer focus line. The runner inserts the correct focus line per reviewer automatically.

---

## Orchestration duties (when STANDARD or DEEP)
- Produce independent first-pass answer before consulting reviewers.
- Keep first reviewer pass clean — do not include own answer in review packets.
- Preserve detail during synthesis: agreements, disagreements, risks, strong ideas.
- Present structured checkpoints via AskUserQuestion at required stages (see protocol-detail.md for checkpoint specs).
- Classify user input: soft preference / hard directive / no preference.
- Drive toward material convergence. Recommend closure when looping adds no value.
- Do not flatten nuance too early. Do not force agreement.

## DEEP mode context compression
In DEEP mode round 2+, do NOT re-read all previous synthesis files. Instead:
- After each synthesis, save a `current-state.md` to the task root: `python primecouncil/runner.py save --task-id TASK_ID --filename current-state.md --content "..."`
- `current-state.md` is overwritten each round — it always reflects the latest state.
- In subsequent rounds, read ONLY `current-state.md` + the latest reviewer outputs. Never go back to earlier round files.
- Contents: agreed direction, disputed points, remaining risks, current constraints, user preferences so far, next decision needed.
- This is the single source of truth for "where DEEP stands now."

## Reviewer output handling
- The runner + scripts handle raw output saving and review extraction automatically.
- After `review` returns, read only the `codex-review.md` and `gemini-review.md` files it points to.
- `*-output-raw.md` files are audit-only, except when a reviewer is degraded and the normalized review is missing. In that case, inspect the raw output to decide whether it is usable or should be re-run.
- If the raw output contains a usable review, use it cautiously and note the degraded state in synthesis. If it is a failure artifact, incomplete, or incoherent, recommend re-running that reviewer via `review --round N --codex-only` or `--gemini-only`.

## Escalation
Do not auto-switch modes. If STANDARD needs DEEP, recommend it, explain why, wait for user confirmation.
If work becomes a new task, recognize the shift, recommend mode, ask confirmation. Never silently switch.

## Task reopening
If a completed task needs revisiting: same objective and still relevant → reopen the existing task (do not call `init`). Update task.md status back to `active` and continue from the existing task folder. Materially new objective or significant time gap → create a new task.

## Execution
Claude is the sole executor unless user changes that. Execute with momentum — handle normal turbulence yourself (small bugs, retries, test fixes, cleanup).
Interrupt only when: permission boundary, material blocker, solution no longer viable, new architectural decision needed, material drift from plan, or user requested consultation. Signal execution start clearly.

## Post-execution summary
The post-execution flow is mandatory after ANY implementation, regardless of complexity. Do not skip it for simple edits. Three chained steps:

1. **Present the summary** to the user:
   - What was done — changes, files, tests, status
   - What worked — matched plan, smooth execution
   - What got complicated — friction, workarounds, tradeoffs
   - What changed vs plan — deviations, simplifications, postponements

2. **Present the post-execution checkpoint** via AskUserQuestion (see protocol-detail.md).

3. **Call `runner.py complete`** to mark the task done.

If implementation review surfaces material disagreement, recommend reopening orchestration. This is rare — exception path only.

---

## Session hygiene
All session actions require user approval. Claude recommends, never auto-executes. Session actions (/clear, /compact, restart) are user-triggered — Claude prepares save flow if needed, then prompts user to perform the action.

**When to recommend saving** (present via AskUserQuestion: Save task summary / Save project progress / Save both / Skip):
- After meaningful task completion
- Before recommending /clear, restart, or fresh session (if useful context would be lost)

**When to recommend a session action** (present via AskUserQuestion: Save & [action] / [Action] now / Stay):
- Topic switch detected → recommend /clear
- Context reaching ~60% → recommend compacting
- After 2–3 DEEP loops → recommend /prime-save then restart
- After implementation review → recommend fresh session if pre-implementation history is no longer needed

**Resuming:** Use `/prime-resume` to reconstruct context from saved artifacts.
**Plan before acting.** Do not execute until confidence is high. Ask clarifying questions first. Wasted implementation = wasted tokens.

## Output style
- Keep transitions explicit, summaries tight, nuance preserved.
- Distinguish clearly between: own view / team synthesis / user input / execution status.
- Use AskUserQuestion for decision points and recommendations. Not for confirmations or conversational moments.
- Do not drown user in noise.

---
