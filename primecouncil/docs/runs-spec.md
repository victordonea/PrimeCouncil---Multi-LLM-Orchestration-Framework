# Runs — Folder Structure and Conventions

All orchestrated task runs are stored under `primecouncil/runs/`.

---

## Task ID format
Hybrid: `YYYY-MM-DD-task-NNN-short-slug`
Example: `2026-03-31-task-001-packet-system`

- Date = task start date
- NNN = sequential number
- Slug = short human-readable label

---

## Folder structure

```
primecouncil/runs/
  2026-03-31-task-001-packet-system/
    task.md                              # task metadata
    round-01/
      claude-first-pass.md               # Claude's independent answer
      packet-codex.md                    # packet sent to Codex
      packet-gemini.md                   # packet sent to Gemini
      codex-output-raw.md               # raw Codex CLI output
      codex-review.md                    # normalized review
      gemini-output-raw.md              # raw Gemini CLI output
      gemini-review.md                   # normalized review
      synthesis.md                       # Claude's synthesis
    round-02/
      packet-codex.md
      packet-gemini.md
      codex-output-raw.md
      codex-review.md
      gemini-output-raw.md
      gemini-review.md
      synthesis.md
      final-recommendation.md           # final integrated recommendation
    implementation-review/               # optional
      packet-codex.md
      packet-gemini.md
      codex-output-raw.md
      codex-review.md
      gemini-output-raw.md
      gemini-review.md
      claude-implementation-summary.md
      decision.md
```

---

## task.md contents
Minimal metadata file per task:
- Task ID
- Task label
- Mode (STANDARD / DEEP)
- Status (active / complete / abandoned)
- Start date
- Rounds completed
- Brief objective (1–3 lines)

---

## What is mandatory vs optional

**Always saved (every round):**
- Packets sent to reviewers
- Raw reviewer outputs
- Normalized reviewer reviews
- Claude's synthesis

**Always saved (round-01):**
- Claude's first-pass answer

**Always saved (final round):**
- Final recommendation

**Optional:**
- Implementation review folder (only when review is run)
- task.md (recommended but not blocking)

---

## Key rules
- Nothing important should live only in terminal scrollback.
- Raw outputs are for audit. Normalized reviews are for Claude consumption.
- Claude references normalized reviews, never raw outputs, in subsequent rounds.
- Long tasks must be traceable. Any round can be audited from saved files.
- Tasks can be resumed from saved artifacts after a session reset.