# Claude skill lifecycle helper
claude-skill-update() {
  local ws="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
  claude skill update || return 1

  # Auto-commit new/changed skills into workspace (claude-config paths)
  if ! git -C "$ws" diff --quiet -- claude-config/skills/ claude-config/skills-lock.json 2>/dev/null || \
     [[ -n "$(git -C "$ws" ls-files --others --exclude-standard -- claude-config/skills/ 2>/dev/null)" ]]; then
    git -C "$ws" add claude-config/skills claude-config/skills-lock.json claude-config/settings.json claude-config/commands/
    git -C "$ws" commit -m "chore(skills): sync well-known skills after claude skill update"
    echo "claude-skill-update: committed claude-config skill changes"
  else
    echo "claude-skill-update: no changes to commit"
  fi
}
