#!/bin/bash
set -euo pipefail

# Read user prompt from stdin JSON
input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // empty')

# Extract keywords (significant words, >3 chars)
keywords=$(echo "$prompt" | tr '[:upper:]' '[:lower:]' | \
  grep -oE '\b[a-z]{4,}\b' | head -5 | tr '\n' ' ')

# Output context (stdout = auto-injected, no JSON needed)
if [[ -n "$keywords" ]]; then
  echo "[CONTEXT] Search relevant sources for: $keywords"
  echo "- retrieve_memory('$keywords')"
  echo "- Check recent plans in ~/.claude/plans/"
fi

exit 0
