#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: review-codex.sh <prompt-file>"
  exit 1
fi

PROMPT_FILE="$1"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Prompt file not found: $PROMPT_FILE"
  exit 1
fi

PROMPT="$(cat "$PROMPT_FILE")"

codex exec -m gpt-5.4 --ephemeral "$PROMPT"