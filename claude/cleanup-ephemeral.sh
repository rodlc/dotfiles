#!/bin/bash
# Cleanup Claude ephemeral files older than 72h
CLAUDE_DIR="$HOME/.claude"
MAX_AGE=72  # heures

# Plans: delete si hook:ignored ET >72h ET PAS notion:posted
find "$CLAUDE_DIR/plans" -name "*.md" -mmin +$((MAX_AGE*60)) -exec sh -c '
  grep -q "hook:ignored" "$1" && ! grep -q "notion:posted" "$1" && rm -v "$1"
' _ {} \;

# Todos + session-env: delete >72h
find "$CLAUDE_DIR/todos" -name "*.json" -mmin +$((MAX_AGE*60)) -delete
find "$CLAUDE_DIR/session-env" -type f -mmin +$((MAX_AGE*60)) -delete
