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

# Context injection moved to UserPromptSubmit hook
echo '{}'
