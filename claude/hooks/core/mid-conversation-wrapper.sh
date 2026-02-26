#!/bin/bash
COOLDOWN=30
LOCK_FILE="/tmp/claude-mid-conv-last-trigger"

# Read stdin once (hook passes JSON context)
input=$(cat)

# Fast cooldown check in pure bash — skip Node entirely
if [ -f "$LOCK_FILE" ]; then
  last=$(< "$LOCK_FILE")
  now=$(date +%s)
  if (( now - last < COOLDOWN )); then
    exit 0
  fi
fi

# Quick-skip: trivial prompts — overrides (#remember, #skip) bypass length gate
msg=$(printf '%s' "$input" | jq -r '.message // ""' 2>/dev/null)
case "$msg" in
  *"#remember"*|*"#skip"*) ;;
  *) [ ${#msg} -lt 20 ] && exit 0 ;;
esac

date +%s > "$LOCK_FILE"
printf '%s' "$input" | exec node ~/.claude/hooks/core/mid-conversation.js
