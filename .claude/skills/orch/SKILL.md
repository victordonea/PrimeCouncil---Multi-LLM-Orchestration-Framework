---
name: orch
description: Toggle PrimeCouncil orchestration state. Use /orch on, /orch off, /orch standard, /orch deep, /orch manual, or /orch status.
disable-model-invocation: true
argument-hint: [on|off|standard|deep|manual|status]
---

# /orch — Orchestration State Control

Manage persistent orchestration state in `primecouncil/orch-state.json`.

## Read current state first

Read `primecouncil/orch-state.json`. If it doesn't exist, treat current state as `{"orch": "off", "default_mode": "manual"}`.

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
Show usage: `/orch [on|off|standard|deep|manual|status]`

## Write the updated state

Write the updated JSON to `primecouncil/orch-state.json`:
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
