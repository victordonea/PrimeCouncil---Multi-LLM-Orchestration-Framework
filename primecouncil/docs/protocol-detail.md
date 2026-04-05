# Protocol Detail — STANDARD and DEEP Stage Walkthroughs

This file contains the full stage-by-stage protocols for STANDARD and DEEP modes.
Load this only when actually executing a packetized orchestration step.

---

## Structured checkpoints — AskUserQuestion

All decision points use AskUserQuestion with clickable options. Design rules:
- Only for real decision points, not confirmations or conversational moments.
- Do not present AskUserQuestion if the path is already explicit (user said "GO DEEP" → no mode picker).
- If the user responds via "Other" or free text, Claude still classifies it as soft preference / hard directive / no preference.
- Session actions (/clear, /compact) are user-triggered — Claude prepares save flow if needed, then prompts user to perform the action.

### Mode recommendation checkpoint
*When Claude detects a task and recommends a mode (not when user already specified one).*
Header: "Mode" | Options:
- **STANDARD** — Independent + combined review round
- **DEEP** — Multiple rounds until convergence
- **DIRECT** — No reviewers, Claude handles alone

### Escalation checkpoint
*When STANDARD needs DEEP, or scope changed materially.*
Header: "Mode" | Options:
- **Switch to DEEP** — Multiple rounds for deeper convergence
- **Stay in STANDARD** — Continue current mode

### Post-execution checkpoint
*After implementation + execution summary. Separate from the decision protocol stages.*
Header: "Next step" | Options:
- **Accept & close task** — Implementation approved, mark task complete
- **Send implementation to reviewers** — Codex and Gemini review what was built
- **Rethink this** — Go back and revisit the approach
*Follow-on: Accept & close task → call runner.py complete, recommend save. Send implementation to reviewers → Claude builds impl review packet. Rethink this → Claude recommends mode for the issue.*

---

## STANDARD decision protocol

### Stage 0 — Activation
Claude confirms: task name, objective, mode = STANDARD, orchestration active.

### Stage 1 — Claude independent first pass
Claude produces an independent answer: proposed solution, reasoning, assumptions, tradeoffs, uncertainties.

### Stage 2 — Clean delegation
Claude sends only clean task context to Codex and Gemini via packet. This includes: user's request, relevant files/code/project context, constraints, success criteria, known risks.
Claude's own answer must NOT be included in this first review packet.

### Stage 3 — Independent reviews
Codex and Gemini each produce an independent answer using the shared reviewer format.

### Stage 4 — Synthesis
Claude synthesizes all three answers. Must preserve: agreements, disagreements, strong ideas, major risks, edge cases, alternatives, unresolved tradeoffs.

**Synthesis preservation rules:**
- Every unique idea from any reviewer must appear. Merge similar points, but never delete a unique one.
- Disagreements must preserve each side's reasoning, not just the positions.
- If an idea doesn't fit a category, create one. Don't force-fit or drop it.
- Use lightweight source attribution in synthesis.md for readability:
  [Codex] raised X — [Gemini] proposed Y — [Claude] initially preferred Z — [Shared] all three agreed on A
- When converting synthesis into the round-2 reviewer packet, remove attribution. Keep ideas and reasoning only. Exception: include attribution only when source matters materially (e.g., minority concern, unresolved disagreement where reasoning lineage matters).

### Stage 5 — Human checkpoint
Claude presents structured checkpoint via AskUserQuestion.
Header: "Checkpoint" | Options:
- **Continue** — Proceed to combined review
- **Add preference** — Soft input that influences direction
- **Add directive** — Hard constraint, binding unless impossible
*Follow-on: Continue → Stage 6. Add preference/directive → Claude asks for details, proceeds to Stage 6. Pause or early close available via "Other" (Claude confirms if user wants to skip combined review).*

### Stage 6 — Combined second-pass review
Claude presents synthesis + user input to Codex, Gemini, and himself. All three review the combined view.

### Stage 7 — Final integration
Claude produces the final STANDARD recommendation: recommended path, why it won, remaining minor tradeoffs, what user input changed, recommended next action.
Note when all agents converge rapidly with no remaining disagreement — flag in the final recommendation if agreement may reflect groupthink rather than genuine convergence.

---

## DEEP decision protocol

### Stages 0–6
Same as STANDARD through the combined second-pass review.

### Stage 7 — Re-synthesis
Claude creates updated synthesis. Explicitly tracks: what is now agreed, what is still disputed, what new insight appeared, what risks remain, whether convergence is increasing.
Apply the same synthesis preservation rules from Stage 4 (attribution, no dropping unique ideas, reasoning lineage).
Note when all agents converge rapidly with no remaining disagreement — flag in synthesis if agreement may reflect groupthink rather than genuine convergence.

**Context compression:** Save synthesis as `current-state.md` at the task root (overwritten each round). In subsequent rounds, read only `current-state.md` + latest reviewer outputs — never re-read earlier round files.

### Stage 8 — Human checkpoint
Claude presents structured checkpoint via AskUserQuestion.
Header: "Checkpoint" | Options:
- **Continue** — Another review round
- **Add preference** — Soft input
- **Add directive** — Hard constraint
- **Wrap up** — Produce final recommendation from current synthesis
*Follow-on: Continue → next round. Add preference/directive → Claude asks for details, proceeds to next round. Wrap up → Claude produces final recommendation. Pause available via "Other" → triggers save flow.*

### Stage 9 — Repeat loop
All agents continue reviewing and re-synthesizing until a stop condition is reached. Each iteration overwrites `current-state.md` with the latest state.

### DEEP stop conditions
Stop when any of these is true:
- No material disagreements remain
- No new meaningful insight appears
- One solution clearly dominates
- The user decides to stop (via "Wrap up" or "Other" at checkpoint)
- Claude recommends closure and the user does not object

Do not chase perfect consensus. Seek material convergence.