# First-Pass Review Packet

**Reviewer focus:** Depth of reasoning, hidden assumptions, structural weaknesses.

---

## Task ID
2026-04-02-task-001-dry-run

## Task label
PrimeCouncil file structure review

## Mode
STANDARD

## Round
01

## Objective
Evaluate whether the current PrimeCouncil file and folder structure is clean, maintainable, and ready for real project use.

## Scope
File architecture only: CLAUDE.md, AGENTS.md, GEMINI.md, docs/, packets/templates/, scripts/, runs/.

## Constraints
- Must remain Markdown-native
- No Python runner yet
- No MCP/UI layer yet

## Relevant files
- CLAUDE.md — main Claude operating contract
- AGENTS.md — shared reviewer constitution
- primecouncil/docs/packet-spec.md — packet rules and brevity limits
- primecouncil/docs/runs-readme.md — run folder conventions

## Success criteria
- Structure is clear to a new reader
- No obvious gaps or redundancies
- Naming is consistent
- Files serve single clear purposes

## Reviewer questions
1. Is anything missing that would block real project use?
2. Is there any redundancy between files?
3. Are the naming conventions clear and consistent?

## Required output format
Use the reviewer format from AGENTS.md: Verdict, Strongest points, Risks/weaknesses, Recommended changes, Open questions, Confidence.