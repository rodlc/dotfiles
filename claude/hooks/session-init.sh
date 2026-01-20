#!/bin/bash
set -euo pipefail

# Cleanup ephemeral files in background
"$HOME/Code/rodlc/dotfiles/claude/cleanup-ephemeral.sh" 2>/dev/null &

PLANS_DIR="$HOME/.claude/plans"

# Mark orphan plans (no marker) as ignored
shopt -s nullglob
for plan in "$PLANS_DIR"/*.md; do
  [ -f "$plan" ] || continue
  grep -q "notion:posted\|hook:ignored" "$plan" || echo "<!-- hook:ignored:$(date +%s) -->" >> "$plan"
done
shopt -u nullglob

# Detect local files not symlinked (divergence prevention)
for dir in commands skills; do
  for f in "$HOME/.claude/$dir"/*.md "$HOME/.claude/$dir"/*/; do
    [ -e "$f" ] || continue
    [ -f "$f" ] || continue  # Skip directories
    [ -L "$f" ] || echo "[WARN] Local file not in dotfiles: $f" >&2
  done
done

# Inject context for Claude
cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "[SESSION INIT] Execute before user task:\n1. retrieve_memory('active projects recent context')\n2. notion_query_database('68d1e0ee-a70a-4a27-b723-dde6ad636904', filter: Done=false)"
  }
}
EOF
