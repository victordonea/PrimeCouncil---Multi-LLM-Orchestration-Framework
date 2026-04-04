#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: review-gemini.sh <prompt-file> <output-file> [session-id]"
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

# Read config from config.json (resolved relative to this script)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
GEMINI_MODEL="$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('gemini_model', 'gemini-3-flash-preview'))" 2>/dev/null || echo "gemini-3-flash-preview")"

# Session ID file — written next to raw output for runner to capture
SESSION_FILE="$OUTPUT_DIR/gemini-session.txt"

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

# Capture the most recent Gemini session ID via --list-sessions
# NOTE: assumes newest session is listed first. Verify ordering if issues arise.
capture_gemini_session() {
  local sid
  sid="$(gemini --list-sessions 2>/dev/null | head -1 | awk '{print $1}')" || true
  if [ -n "$sid" ]; then
    echo "$sid" > "$SESSION_FILE"
    echo "Session ID captured: $sid"
  fi
}

# Run Gemini with fallback chain for session resume
run_gemini() {
  if [ -n "$RESUME_SESSION" ]; then
    # Try 1: resume stored session
    if OUTPUT="$(gemini --resume "$RESUME_SESSION" -m "$GEMINI_MODEL" -p "$PROMPT" 2>&1)"; then
      echo "$OUTPUT"
      return 0
    fi
    echo "Resume with stored session failed. Trying --resume latest..." >&2
    # Try 2: resume latest
    if OUTPUT="$(gemini --resume latest -m "$GEMINI_MODEL" -p "$PROMPT" 2>&1)"; then
      echo "$OUTPUT"
      return 0
    fi
    echo "Resume latest failed. Starting fresh session..." >&2
  fi
  # Fresh session
  gemini -m "$GEMINI_MODEL" -p "$PROMPT" 2>&1
}

# Attempt 1
if OUTPUT="$(run_gemini)"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
  capture_gemini_session
  exit 0
fi

echo "Gemini attempt 1 failed. Retrying..."

# Attempt 2 (always fresh on retry — don't compound resume failures)
if OUTPUT="$(gemini -m "$GEMINI_MODEL" -p "$PROMPT" 2>&1)"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
  capture_gemini_session
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
