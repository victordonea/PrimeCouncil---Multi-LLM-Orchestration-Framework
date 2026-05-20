#!/usr/bin/env bash
# PrimeCouncil status line — displays orchestration state + session info
# Receives session JSON on stdin from Claude Code
# Uses python for all JSON parsing (no jq dependency)

input=$(cat)

# Extract session info from Claude Code JSON via python (read from stdin, not argv).
# Tab-separate output so model names with spaces ("Opus 4.7 (1M context)") don't get split.
PARSED="$(echo "$input" | python -c "
import json, sys
try:
    d = json.load(sys.stdin)
    model = d.get('model', {}).get('display_name', '?')
    ctx = int(d.get('context_window', {}).get('used_percentage', 0))
    print(f'{ctx}\t{model}')
except:
    print('0\t?')
" 2>/dev/null || echo "0	?")"
CTX="${PARSED%%	*}"
MODEL="${PARSED#*	}"

# Read orchestration state — resolve the path via Python so Windows + Git Bash
# (/c/... vs C:\...) doesn't trip the python json.load call.
STATE_INFO="$(python -c "
import json, os, sys
sd = os.path.dirname(os.path.abspath(sys.argv[1]))
sf = os.path.join(sd, '..', 'orch-state.json')
try:
    d = json.load(open(sf))
    print(f\"{d.get('orch', 'off').upper()}\t{d.get('default_mode', 'manual').upper()}\")
except:
    print('OFF\tMANUAL')
" "$0" 2>/dev/null || printf 'OFF\tMANUAL')"
ORCH="${STATE_INFO%%	*}"
MODE="${STATE_INFO#*	}"

if [ "$ORCH" = "ON" ]; then
  echo "ORCH:$ORCH | MODE:$MODE | [$MODEL] ${CTX}% ctx"
else
  echo "ORCH:$ORCH | [$MODEL] ${CTX}% ctx"
fi
