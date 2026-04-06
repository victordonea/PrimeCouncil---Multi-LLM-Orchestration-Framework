---
name: prime-orch
description: Toggle PrimeCouncil orchestration state. Use /prime-orch on, /prime-orch off, /prime-orch standard, /prime-orch deep, /prime-orch manual, or /prime-orch status.
disable-model-invocation: true
argument-hint: [on|off|standard|deep|manual|status]
---

# /prime-orch — Orchestration State Control

Manage persistent orchestration state in `primecouncil/prime-orch-state.json`.

## Read current state first

Read `primecouncil/prime-orch-state.json`. If it doesn't exist, treat current state as `{"orch": "off", "default_mode": "manual"}`.

## Handle the command: `$ARGUMENTS`

### `on`
Set `orch` to `"on"`. Keep current `default_mode` unchanged.

### `off`
Set `orch` to `"off"`. Keep current `default_mode` unchanged.

### `standard`
Set `orch` to `"on"` and `default_mode` to `"standard"`.

### `deep`
Set `orch` to `"on"` and `default_mode` to `"deep"`.

### `manual`
Set `orch` to `"on"` and `default_mode` to `"manual"`.

### `status`
Read and display the current state. Do not modify anything.
Format: "Orchestration: [on/off] | Default mode: [mode]"

### No argument or unrecognized
Show usage: `/prime-orch [on|off|standard|deep|manual|status]`

## Write the updated state

Write the updated JSON to `primecouncil/prime-orch-state.json`:
```json
{
  "orch": "...",
  "default_mode": "..."
}
```

Confirm the change to the user in one short line.

## Rules
- This skill controls persistent defaults only.
- `GO STANDARD` / `GO DEEP` / `GO DIRECT` are conversational per-task overrides — they do NOT change `orch-state.json`.
- Never auto-trigger this skill. It is user-invoked only.
