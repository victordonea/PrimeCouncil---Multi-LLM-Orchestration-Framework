# Generation Rules for docs/project-context.md

- Write for both humans and LLMs.
- Prefer bullets over long prose.
- Keep the document concise, dense, and high-signal.
- Prefer the shortest version that still lets a new LLM fully understand the repo correctly and work safely.
- Simple repos may need 80-120 lines. Complex repos may need 300+.
- Every line should add understanding. Cut filler, not substance.
- Do not summarize every file in the repo.
- Focus on purpose, structure, workflow, commands, constraints, and important files.
- Use exact file paths in backticks.
- Use exact commands in backticks.
- Clearly separate:
  - confirmed facts
  - inferred facts
  - unknowns
- If something is unclear, say so instead of guessing.
- Do not use marketing language.
- Do not pad sections with filler.
- Do not repeat short repo identity text already present in root CLAUDE.md unless needed for clarity. This file should go deeper, not sideways.
- When listing files, prioritize the few files that define architecture, workflow, or risk. Avoid long directory dumps.
- Highlight dangerous operations, no-touch areas, deployment cautions, generated files, and validation steps.
- Always include the metadata header block (generation date, scan mode, confidence, last reviewed date) so the file is auditable.
- Make the file useful as:
  - a repo onboarding brief
  - a refresher for future Claude sessions
  - a quick reference for the user

---

# Template

# Project Context

- **Generated:** [YYYY-MM-DD]
- **Source mode:** [Selective scan / Full scan / Manual]
- **Confidence:** [High / Medium / Low]
- **Last reviewed by user:** [YYYY-MM-DD or blank]

---

## 1. Project Identity

- **Name:** [Project name]
- **Purpose:** [One-sentence description of what the project is for]
- **Current stage:** [e.g. planning, active development, production, migration]
- **Primary users / audience:** [Who this project is for]

---

## 2. What This Project Does

### Core function
- [Plain-English explanation of what the project does]

### Main capabilities
- [Capability 1]
- [Capability 2]
- [Capability 3]

### What it is not
- [Important anti-definition 1]
- [Important anti-definition 2]

---

## 3. Current Goals

### Immediate priorities
- [Priority 1]
- [Priority 2]
- [Priority 3]

### Current focus
- [What is actively being built, fixed, or validated right now]

### Intentionally deferred
- [Deferred item 1]
- [Deferred item 2]

---

## 4. System / Product Shape

### Main components
- [Component / service / subsystem 1] — [what it does]
- [Component / service / subsystem 2] — [what it does]
- [Component / service / subsystem 3] — [what it does]

### Main entities / modules
- [Entity / module 1] — [role]
- [Entity / module 2] — [role]
- [Entity / module 3] — [role]

### High-level flow
1. [Step 1]
2. [Step 2]
3. [Step 3]

### External services / dependencies
- [Service 1] — [why it matters]
- [Service 2] — [why it matters]
- [Service 3] — [why it matters]

---

## 5. Repository Map

### Key top-level folders
- [folder-or-path] — [what it contains]
- [folder-or-path] — [what it contains]
- [folder-or-path] — [what it contains]

### Highest-signal files
- [file-path] — [why it matters]
- [file-path] — [why it matters]
- [file-path] — [why it matters]

### Suggested reading order
1. [file-path]
2. [file-path]
3. [file-path]

---

## 6. How To Work In This Repo

### Where to start
- [Best first file/doc/folder to read]
- [Best first task or workflow to understand]

### Typical workflow
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Commands / scripts
- [command] — [what it does]
- [command] — [what it does]
- [command] — [what it does]

### Tooling / environment
- [Tool 1] — [how it is used]
- [Tool 2] — [how it is used]
- [Tool 3] — [how it is used]

### Build / run / test / deploy notes
- [Important note 1]
- [Important note 2]
- [Important note 3]

---

## 7. Key Constraints and Conventions

### Important constraints
- [Constraint 1]
- [Constraint 2]
- [Constraint 3]

### Architectural boundaries
- [Boundary 1]
- [Boundary 2]
- [Boundary 3]

### Conventions
- [Convention 1]
- [Convention 2]
- [Convention 3]

### Things not to misunderstand
- [Common confusion 1]
- [Common confusion 2]

---

## 8. Important Files

| File | Why it matters |
|------|----------------|
| [path] | [short reason] |
| [path] | [short reason] |
| [path] | [short reason] |
| [path] | [short reason] |

---

## 9. Open Questions / Risks

### Open questions
- [Question 1]
- [Question 2]
- [Question 3]

### Known risks
- [Risk 1]
- [Risk 2]
- [Risk 3]

### Things that should be verified
- [Uncertain point 1]
- [Uncertain point 2]

---

## 10. Glossary

- **[Term]:** [definition]
- **[Term]:** [definition]
- **[Term]:** [definition]

---

## 11. Confidence Notes

### Confirmed from scanned files
- [Fact 1]
- [Fact 2]

### Inferred but not fully verified
- [Inference 1]
- [Inference 2]

### Not clear from available files
- [Unknown 1]
- [Unknown 2]
