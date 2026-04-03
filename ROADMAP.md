# PrimeCouncil Build Roadmap

## Phase 2 — Optimization & Artifact Baseline
- [x] Step 1: Rewrite CLAUDE.md (lean constitution + router)
- [x] Step 2: Trim AGENTS.md (~93 lines)
- [x] Step 3: Create primecouncil/docs/ files (4 files)
- [x] Step 4: Create packet templates (3 templates)
- [x] Step 5: Patch reviewer scripts (output persistence + retry + marker extraction)
- [x] Step 6: Update GEMINI.md
- [x] Step 7: Manual dry run (both reviewers succeeded)
- [x] Step 8: Post-dry-run fixes

## Phase 3 — Operationalization
- [x] Step 9: Build Python runner (init, save, review, new-round, status)
- [x] Step 10: Claude integration + portable kit (2-part CLAUDE.md, install skill, runner instructions)
- [x] Step 11: Add list command to runner
- [x] Step 12: Add project-progress.md + task-summary.md templates
- [x] Step 13: Build /prime-save skill
- [x] Step 14: Build /prime-resume skill
- [x] Step 15: Update CLAUDE.md session hygiene (prime-save/prime-resume triggers)

## Phase 4 — Validation
- [ ] Step 16: First real task through full workflow (do after Step 24)

## Phase 5 — Production Polish
- [x] Step 17: README.md + runs/INDEX.md

## Phase 6 — Quality & Efficiency
- [x] Step 18: DEEP mode context compression (current-state.md)
- [x] Step 19: Single-reviewer mode (--codex-only, --gemini-only)
- [x] Step 20: User tutorial (primecouncil/docs/user-tutorial.md)

## Phase 7 — Hardening
- [x] Step 21: Config file for paths and models
  Create `primecouncil/config.json`. Centralizes: Codex model name, Gemini model, reviewer script paths, runs directory path, timeout values. Scripts and runner read from this instead of hardcoding.
- [ ] Step 22: Failed run recovery
  Runner detects partial state: packet exists but no review output. Status flags incomplete rounds. Support re-running a specific round without re-initializing. Runner-side only, zero token impact.
- [ ] Step 23: Anti-groupthink guardrails
  In round 2+ synthesis packets: reviewers must state what they CHANGED their mind on and why. Must flag if agreeing only because synthesis was persuasive. Claude notes in synthesis when all three agree suspiciously fast. ~2 lines added to templates.
- [ ] Step 24: Structured checkpoints in orchestration
  At human checkpoints during STANDARD/DEEP, Claude presents structured choices: Continue / Add preference / Add directive / Pause / Approve DEEP escalation / Close task. Add checkpoint format rules to CLAUDE.md.
