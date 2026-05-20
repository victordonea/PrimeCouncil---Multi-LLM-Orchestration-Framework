# PrimeCouncil

A multi-LLM orchestration framework where Claude leads a structured team of AI reviewers to make better decisions.

## How it works

- **Claude** is the orchestrator, synthesizer, and executor
- **Codex** is the deep analytical reviewer — finds hidden assumptions, edge cases, structural weaknesses
- **Gemini** is the creative reviewer — brings fresh perspectives, UX thinking, alternative framing
- **You** are the strategic supervisor — set goals, make final calls, steer direction

Each reviewer works independently before seeing the others' answers. This prevents groupthink and produces genuinely diverse perspectives that Claude then synthesizes.

## Three modes

- **DIRECT** — Claude answers alone. For simple, informational, or speed-priority tasks.
- **STANDARD** — Full team review. One independent round, one convergence round, user checkpoints. The strong default for real decisions.
- **DEEP** — Multiple rounds until the team genuinely agrees. For high-stakes architectural choices.

## Quick start

1. Copy the `.claude/primecouncil/` folder (which now contains AGENTS.md + GEMINI.md inside it) and the `.claude/skills/` folder into your project repo
2. Open Claude Code in the repo
3. Run `/prime-install` — it sets up CLAUDE.md and fills in your project context
4. Say `ORCH ON` and start working

## Commands

| Command | What it does |
|---|---|
| `ORCH ON` | Activate orchestration awareness |
| `ORCH OFF` | Back to normal Claude behavior |
| `GO STANDARD` | Start a STANDARD review task |
| `GO DEEP` | Start a DEEP convergence task |
| `GO DIRECT` | Handle it directly, no reviewers |
| `/prime-save` | Save task and project context before clearing |
| `/prime-resume` | Restore context in a new session |
| `/prime-install` | Set up PrimeCouncil in a new repo |

## File structure

```
your-project/
  CLAUDE.md                    # Project identity + PrimeCouncil managed tripwire block
  .claude/
    skills/                    # PrimeCouncil skills (prime-orch, prime-save, prime-resume, prime-install)
    settings.json              # Status line + permissions
    primecouncil/
      AGENTS.md                # Shared reviewer constitution
      GEMINI.md                # Gemini-specific reviewer instructions
      ORCHESTRATION.md         # Full orchestration contract (loaded on demand)
      runner.py                # Mechanical automation (folders, packets, reviewers)
      config.json              # Centralized paths, models, timeouts
      orch-state.json          # Persistent ORCH on/off + default mode (per-machine, gitignored)
      scripts/                 # Reviewer CLI adapters + statusline
      packets/templates/       # Packet templates for each review type
      docs/                    # Protocol details, specs, host-repo pattern, user tutorial
      runs/                    # Task history — one folder per task
```

## Key design principles

- **First-pass independence** — each AI reviews independently before seeing others' answers
- **Material disagreement** — the system surfaces real conflicts instead of forcing fake agreement
- **Token efficiency** — lean always-loaded files, on-demand deep context, automatic review extraction
- **Artifact discipline** — every decision is saved, traceable, and auditable
- **Recommend, never auto-execute** — Claude suggests actions, you approve

## Reading order

If you want to understand the full system:

1. This README (you're here)
2. `CLAUDE.md` — the operating contract
3. `.claude/primecouncil/AGENTS.md` — shared reviewer rules
4. `.claude/primecouncil/docs/packet-spec.md` — how review packets work
5. `.claude/primecouncil/docs/protocol-detail.md` — full STANDARD/DEEP stage walkthrough
6. `.claude/primecouncil/docs/runs-spec.md` — run folder conventions