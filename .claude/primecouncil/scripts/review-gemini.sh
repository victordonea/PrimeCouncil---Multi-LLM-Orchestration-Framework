#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: review-gemini.sh <prompt-file> <output-file> [resume-marker]"
  exit 1
fi

PROMPT_FILE="$1"
OUTPUT_FILE="$2"
RESUME_SESSION="${3:-}"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Prompt file not found: $PROMPT_FILE"
  exit 1
fi

# Create output directory if needed
OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
mkdir -p "$OUTPUT_DIR"

PROMPT="$(cat "$PROMPT_FILE")"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Read config from config.json. Resolve the path inside Python so Windows + Git Bash
# (/c/... vs C:\...) doesn't trip json.load.
GEMINI_MODEL="$(python -c "
import json, os, sys
sd = os.path.dirname(os.path.abspath(sys.argv[1]))
cf = os.path.join(sd, '..', 'config.json')
try:
    d = json.load(open(cf))
    print(d.get('gemini_model', 'gemini-3-flash-preview'))
except:
    print('gemini-3-flash-preview')
" "$0" 2>/dev/null || echo "gemini-3-flash-preview")"

# Derive normalized review filename: gemini-output-raw.md -> gemini-review.md
REVIEW_FILE="$(echo "$OUTPUT_FILE" | sed 's/-output-raw\.md/-review.md/')"

# Function to extract clean review from raw output
extract_review() {
  local raw="$1"
  if echo "$raw" | grep -q "===REVIEW START==="; then
    echo "$raw" | sed -n '/===REVIEW START===/,$ p' | tail -n +2 > "$REVIEW_FILE"
    echo "Review extracted to $REVIEW_FILE"
  else
    echo "$raw" > "$REVIEW_FILE"
    echo "Warning: ===REVIEW START=== marker not found. Full output saved as review."
  fi
}

# Detect resume failure via stdout marker (Gemini exits 0 even on bad --resume)
resume_failed() {
  echo "$1" | grep -q "Invalid session identifier\|Error resuming session"
}

# Run Gemini. If RESUME_SESSION is set, resume the latest session for this project.
# Falls back to a fresh session if resume returns an error in stdout.
run_gemini() {
  # Ensure Gemini finds GEMINI.md and AGENTS.md by running from the primecouncil directory
  local PRIME_DIR
  PRIME_DIR="$(cd "$(dirname "$CONFIG_FILE")" && pwd)"
  pushd "$PRIME_DIR" > /dev/null

  # </dev/null on every CLI invocation: prevents future hangs if Gemini ever
  # adopts stdin-appending behavior (Codex 0.129+ does this, hangs Python subprocess).
  if [ -n "$RESUME_SESSION" ]; then
    OUTPUT="$(gemini --resume latest -m "$GEMINI_MODEL" -p "$PROMPT" </dev/null 2>&1)" || true
    if [ -n "$OUTPUT" ] && ! resume_failed "$OUTPUT"; then
      echo "$OUTPUT"
      popd > /dev/null
      return 0
    fi
    echo "Resume latest failed or returned error. Starting fresh session..." >&2
  fi
  
  local FINAL_OUTPUT
  FINAL_OUTPUT="$(gemini -m "$GEMINI_MODEL" -p "$PROMPT" </dev/null 2>&1)"
  local EXIT_CODE=$?
  echo "$FINAL_OUTPUT"
  popd > /dev/null
  return $EXIT_CODE
}

# Attempt 1
if OUTPUT="$(run_gemini)" && [ -n "$OUTPUT" ] && ! resume_failed "$OUTPUT"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
  exit 0
fi

echo "Gemini attempt 1 failed. Retrying with fresh session..."

# Attempt 2 (always fresh on retry)
run_fresh_gemini() {
  local PRIME_DIR
  PRIME_DIR="$(cd "$(dirname "$CONFIG_FILE")" && pwd)"
  pushd "$PRIME_DIR" > /dev/null
  gemini -m "$GEMINI_MODEL" -p "$PROMPT" </dev/null 2>&1
  local EXIT_CODE=$?
  popd > /dev/null
  return $EXIT_CODE
}

if OUTPUT="$(run_fresh_gemini)" && [ -n "$OUTPUT" ] && ! resume_failed "$OUTPUT"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
  exit 0
fi

# Both attempts failed — write failure artifact
cat > "$OUTPUT_FILE" <<EOF
# Review Failed

- Reviewer: Gemini
- Prompt file: $PROMPT_FILE
- Timestamp: $TIMESTAMP
- Attempts: 2
- Status: FAILED

Both attempts failed. This round is degraded.
EOF

echo "Gemini review failed after 2 attempts. Failure artifact written to $OUTPUT_FILE"
exit 1
