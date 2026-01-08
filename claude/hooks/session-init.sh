#!/bin/bash
set -euo pipefail
PLANS_DIR="$HOME/.claude/plans"

# Mark orphan plans (no marker) as ignored
shopt -s nullglob
for plan in "$PLANS_DIR"/*.md; do
  [ -f "$plan" ] || continue
  grep -q "notion:posted\|hook:ignored" "$plan" || echo "<!-- hook:ignored:$(date +%s) -->" >> "$plan"
done
shopt -u nullglob

# Inject context for Claude
cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "[SESSION INIT] Execute before user task:\n1. retrieve_memory('active projects recent context')\n2. notion_query_database('68d1e0ee-a70a-4a27-b723-dde6ad636904', filter: Done=false)"
  }
}
EOF
