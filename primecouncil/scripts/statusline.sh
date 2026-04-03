#!/usr/bin/env bash
# PrimeCouncil status line — displays orchestration state + session info
# Receives session JSON on stdin from Claude Code
# Uses python3 for all JSON parsing (no jq dependency)

input=$(cat)

# Extract session info from Claude Code JSON via python3
read -r MODEL CTX <<< "$(python3 -c "
import json, sys
try:
    d = json.loads(sys.argv[1])
    model = d.get('model', {}).get('display_name', '?')
    ctx = int(d.get('context_window', {}).get('used_percentage', 0))
    print(model, ctx)
except:
    print('? 0')
" "$input" 2>/dev/null || echo "? 0")"

# Read orchestration state (resolve relative to this script)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$SCRIPT_DIR/../orch-state.json"

if [ -f "$STATE_FILE" ]; then
  ORCH=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('orch', 'off').upper())" 2>/dev/null || echo "OFF")
  MODE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('default_mode', 'manual').upper())" 2>/dev/null || echo "MANUAL")
else
  ORCH="OFF"
  MODE="MANUAL"
fi

if [ "$ORCH" = "ON" ]; then
  echo "ORCH:$ORCH | MODE:$MODE | [$MODEL] ${CTX}% ctx"
else
  echo "ORCH:$ORCH | [$MODEL] ${CTX}% ctx"
fi
