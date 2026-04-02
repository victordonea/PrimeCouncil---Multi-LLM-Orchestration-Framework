#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: review-codex.sh <prompt-file> <output-file>"
  exit 1
fi

PROMPT_FILE="$1"
OUTPUT_FILE="$2"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Prompt file not found: $PROMPT_FILE"
  exit 1
fi

# Create output directory if needed
OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
mkdir -p "$OUTPUT_DIR"

PROMPT="$(cat "$PROMPT_FILE")"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

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

# Attempt 1
if OUTPUT="$(codex exec -m gpt-5.4 --ephemeral "$PROMPT" 2>&1)"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
  exit 0
fi

echo "Codex attempt 1 failed. Retrying..."

# Attempt 2
if OUTPUT="$(codex exec -m gpt-5.4 --ephemeral "$PROMPT" 2>&1)"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
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