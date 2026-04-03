# Packet Specification

Packets are the structured context artifacts Claude produces for each orchestration step.
Template files live in `primecouncil/packets/templates/`.

---

## Core principle
A packet is a **decision brief**, not a conversation export.
Every packet must be self-contained enough to understand, but aggressively concise.

---

## Compactness rules (enforce always)

| Section | Hard limit |
|---|---|
| Objective | 3 lines max |
| Scope | 5 lines max |
| Constraints | 10 bullets max |
| Relevant files | file path + one-line reason each |
| Success criteria | 5 bullets max |
| Reviewer questions | 3–5 max |
| User preferences | only current relevant ones, not full history |
| Synthesis sections | 10 bullets max per section |

**Never include:**
- Full chat history or transcript excerpts
- Repeated protocol text (reviewers already have AGENTS.md)
- Long project background (reference project-context.md instead)
- Claude's own answer in first-pass review packets
- Secrets, API keys, credentials, or personal/client-sensitive data

---

## Packet types

### 1. First-pass review packet
Used when Claude sends clean task context to Codex and Gemini for independent review.

**Sections:**
- Task ID
- Task label
- Mode
- Round number
- Objective
- Scope
- Constraints
- Relevant files
- Success criteria
- Reviewer questions
- Required output format (reference AGENTS.md reviewer format)

**Rule:** Must NOT contain Claude's own first-pass answer.

### 2. Synthesis review packet
Used after Claude combines all views for a second-pass combined review.

**Sections:**
- Task ID
- Mode
- Round number
- Current synthesis (agreements, disagreements, strong ideas, remaining risks, unresolved tradeoffs)
- Unresolved questions
- User feedback so far (classified: soft/hard/none)
- Reviewer focus for this round

**Rule:** Must reflect what changed since last round, not restate everything.

### 3. Implementation review packet
Used after execution for optional post-implementation review.

**Sections:**
- Task ID
- Original plan (brief)
- What was implemented
- Deviations from plan
- What worked
- What got messy
- Tests/checks run
- Open concerns
- Reviewer questions

**Rule:** Focus on deviations and risks, not re-describing the whole task.

---

## Same packet body for both reviewers
Codex and Gemini receive the same canonical packet structure.
The only permitted difference is an optional short reviewer-focus line at the top:
- For Codex: "Focus: depth of reasoning, hidden assumptions, structural weaknesses."
- For Gemini: "Focus: UX/human considerations, alternative framing, unconventional ideas."

Do not create divergent packet systems per reviewer.

---

## File naming conventions

Packets in run folders follow this naming:
- `packet-codex.md` / `packet-gemini.md` — the sent packets
- `codex-output-raw.md` / `gemini-output-raw.md` — raw CLI output (audit only)
- `codex-review.md` / `gemini-review.md` — normalized review (Claude-consumable)
- `claude-first-pass.md` — Claude's independent first answer
- `synthesis.md` — round synthesis
- `final-recommendation.md` — final integrated recommendation
- `claude-implementation-summary.md` — post-execution summary
- `decision.md` — implementation review decision

See `runs-readme.md` for full folder structure.