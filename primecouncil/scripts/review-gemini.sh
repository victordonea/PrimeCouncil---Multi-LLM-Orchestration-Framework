#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: review-gemini.sh <prompt-file> <output-file>"
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

# Attempt 1
if OUTPUT="$(gemini -p "$PROMPT" 2>&1)"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
  exit 0
fi

echo "Gemini attempt 1 failed. Retrying..."

# Attempt 2
if OUTPUT="$(gemini -p "$PROMPT" 2>&1)"; then
  echo "$OUTPUT" > "$OUTPUT_FILE"
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