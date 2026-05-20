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

# Read config from config.json. Resolve the path inside Python so Windows + Git Bash
# (/c/... vs C:\...) doesn't trip json.load. All four values come back tab-separated.
CONFIG_VALS="$(python -c "
import json, os, sys
sd = os.path.dirname(os.path.abspath(sys.argv[1]))
cf = os.path.join(sd, '..', 'config.json')
try:
    d = json.load(open(cf))
    print('\t'.join([
        str(d.get('codex_model', 'gpt-5.5')),
        str(d.get('codex_reasoning_effort', 'high')),
        str(d.get('codex_context_window', 1000000)),
        str(d.get('codex_auto_compact_token_limit', 900000)),
    ]))
except:
    print('gpt-5.5\thigh\t1000000\t900000')
" "$0" 2>/dev/null || printf 'gpt-5.5\thigh\t1000000\t900000')"
IFS=$'\t' read -r CODEX_MODEL CODEX_REASONING CODEX_CONTEXT_WINDOW CODEX_AUTO_COMPACT <<< "$CONFIG_VALS"

# Session ID file — written next to raw output for runner to capture
SESSION_FILE="$OUTPUT_DIR/codex-session.txt"

# Temp file for -o output (plain text review). Cleaned up on all exit paths.
REVIEW_TMP="$OUTPUT_DIR/codex-review-tmp.txt"
trap 'rm -f "$REVIEW_TMP"' EXIT

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

# Extract session ID from JSONL stdout (machine-readable, stable contract)
extract_session_id() {
  local jsonl_output="$1"
  local sid
  sid="$(echo "$jsonl_output" | python -c "
import json, sys
for line in sys.stdin:
    try:
        d = json.loads(line)
        if d.get('type') == 'thread.started':
            print(d.get('thread_id', ''))
            break
    except: pass
" 2>/dev/null || echo "")"
  if [ -n "$sid" ]; then
    echo "$sid" > "$SESSION_FILE"
    echo "Session ID captured: $sid"
  fi
}

# Run Codex with --json (JSONL on stdout) and -o (plain text review to file)
run_codex() {
  # Clear stale temp file before each attempt
  rm -f "$REVIEW_TMP"
  # Ensure Codex finds AGENTS.md by running from the primecouncil directory
  local PRIME_DIR
  PRIME_DIR="$(cd "$(dirname "$CONFIG_FILE")" && pwd)"
  pushd "$PRIME_DIR" > /dev/null
  # Prompt is piped via stdin (codex reads from stdin when the prompt arg is `-`).
  if [ -n "$RESUME_SESSION" ]; then
    codex exec resume "$RESUME_SESSION" -m "$CODEX_MODEL" \
      -c model_reasoning_effort="$CODEX_REASONING" \
      -c model_context_window="$CODEX_CONTEXT_WINDOW" \
      -c model_auto_compact_token_limit="$CODEX_AUTO_COMPACT" \
      --json -o "$REVIEW_TMP" - <"$PROMPT_FILE" 2>&1
  else
    codex exec -m "$CODEX_MODEL" \
      -c model_reasoning_effort="$CODEX_REASONING" \
      -c model_context_window="$CODEX_CONTEXT_WINDOW" \
      -c model_auto_compact_token_limit="$CODEX_AUTO_COMPACT" \
      --json -o "$REVIEW_TMP" - <"$PROMPT_FILE" 2>&1
  fi
  local EXIT_CODE=$?
  popd > /dev/null
  # Verify -o produced non-empty output
  if [ ! -s "$REVIEW_TMP" ]; then
    echo "Codex succeeded but -o file is empty or missing" >&2
    return 1
  fi
  return $EXIT_CODE
}

# Attempt 1
if JSONL_OUTPUT="$(run_codex)"; then
  # Review text is in the -o file (plain text)
  OUTPUT="$(cat "$REVIEW_TMP" 2>/dev/null || echo "")"
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
  extract_session_id "$JSONL_OUTPUT"
  exit 0
fi

echo "Codex attempt 1 failed. Retrying..."

# Attempt 2
if JSONL_OUTPUT="$(run_codex)"; then
  OUTPUT="$(cat "$REVIEW_TMP" 2>/dev/null || echo "")"
  echo "$OUTPUT" > "$OUTPUT_FILE"
  extract_review "$OUTPUT"
  extract_session_id "$JSONL_OUTPUT"
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
