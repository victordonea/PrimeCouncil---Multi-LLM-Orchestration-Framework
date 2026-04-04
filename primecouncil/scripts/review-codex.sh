#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: review-codex.sh <prompt-file> <output-file> [session-id]"
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
CODEX_MODEL="$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('codex_model', 'gpt-5.4'))" 2>/dev/null || echo "gpt-5.4")"
CODEX_REASONING="$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('codex_reasoning_effort', 'high'))" 2>/dev/null || echo "high")"

# Session ID file — written next to raw output for runner to capture
SESSION_FILE="$OUTPUT_DIR/codex-session.txt"

# Derive normalized review filename: codex-output-raw.md -> codex-review.md
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

# Extract session ID from Codex output header
# PROVISIONAL: parses human-readable header. Future hardening: use --json
# with thread.started.thread_id for machine-readable capture.
extract_session_id() {
  local raw="$1"
  local sid
  sid="$(echo "$raw" | grep -oP 'session id: \K[0-9a-f-]+' | head -1)" || true
  if [ -n "$sid" ]; then
    echo "$sid" > "$SESSION_FILE"
    echo "Session ID captured: $sid"
  fi
}

# Build the codex command (resume or fresh — no --ephemeral so sessions persist)
run_codex() {
  if [ -n "$RESUME_SESSION" ]; then
    codex exec resume "$RESUME_SESSION" -m "$CODEX_MODEL" -c model_reasoning_effort="$CODEX_REASONING" "$PROMPT" 2>&1
  else
    codex exec -m "$CODEX_MODEL" -c model_reasoning_effort="$CODEX_REASONING" "$PROMPT" 2>&1
  fi
}

# Attempt 1
if OUTPUT="$(run_codex)"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
  extract_session_id "$OUTPUT"
  exit 0
fi

echo "Codex attempt 1 failed. Retrying..."

# Attempt 2
if OUTPUT="$(run_codex)"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
  extract_session_id "$OUTPUT"
  exit 0
fi

# Both attempts failed — write failure artifact
cat > "$OUTPUT_FILE" <<EOF
# Review Failed

- Reviewer: Codex
- Prompt file: $PROMPT_FILE
- Timestamp: $TIMESTAMP
- Attempts: 2
- Status: FAILED

Both attempts failed. This round is degraded.
EOF

echo "Codex review failed after 2 attempts. Failure artifact written to $OUTPUT_FILE"
exit 1
