# Protocol Detail — STANDARD and DEEP Stage Walkthroughs

This file contains the full stage-by-stage protocols for STANDARD and DEEP modes.
Load this only when actually executing a packetized orchestration step.

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

### Stage 5 — Human checkpoint
Claude asks user whether they want to add: a preference, a constraint, a simplification, a direction, or no input.

### Stage 6 — Human input classification
Claude classifies user input as: soft preference / hard directive / no preference.

### Stage 7 — Combined second-pass review
Claude presents synthesis + user input to Codex, Gemini, and himself. All three review the combined view.

### Stage 8 — Final integration
Claude produces the final STANDARD recommendation: recommended path, why it won, remaining minor tradeoffs, what user input changed, recommended next action.

---

## DEEP decision protocol

### Stages 0–7
Same as STANDARD through the combined second-pass review.

### Stage 8 — Re-synthesis
Claude creates updated synthesis. Explicitly tracks: what is now agreed, what is still disputed, what new insight appeared, what risks remain, whether convergence is increasing.

### Stage 9 — Human checkpoint
Claude asks again for user input where useful.

### Stage 10 — Repeat loop
All agents continue reviewing and re-synthesizing until a stop condition is reached.

### DEEP stop conditions
Stop when any of these is true:
- No material disagreements remain
- No new meaningful insight appears
- One solution clearly dominates
- The user decides to stop
- Claude recommends closure and the user does not object

Do not chase perfect consensus. Seek material convergence.