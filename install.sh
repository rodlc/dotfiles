#!/bin/zsh
set -e

DOTFILES_DIR="${0:A:h}"  # script's own directory, whatever the caller's cwd
TIER="${1:-dotfiles}"  # dotfiles | workspace | mcp
source "$DOTFILES_DIR/lib/launchd-roles.zsh"

[[ "$TIER" == "doctor" ]] && exec "$DOTFILES_DIR/doctor.sh" "${2:-mcp}"

source "$DOTFILES_DIR/lib/common.zsh"
for tier_file in "$DOTFILES_DIR"/tiers/*.zsh; do source "$tier_file"; done

cat <<EOF
╔═══════════════════════════════════════════════════════════════╗
║  Dotfiles installer — tier: $TIER
╠═══════════════════════════════════════════════════════════════╣
║  dotfiles  — Shell + Git + Zed + Brew (standalone)
║  workspace — dotfiles + Claude Code + workspace config
║  mcp       — workspace + MCP servers + launchd + memory
╚═══════════════════════════════════════════════════════════════╝

EOF
echo "=====> Installing dotfiles (tier: $TIER)"

case "$TIER" in
  dotfiles)
    install_dotfiles
    echo ""
    echo "💡 To add Claude Code: ./install.sh workspace"
    ;;
  workspace)
    install_dotfiles
    install_workspace
    ;;
  mcp)
    install_dotfiles
    install_workspace
    install_mcp
    ;;
  *)
    echo "Usage: ./install.sh [dotfiles|workspace|mcp|doctor [tier]]"
    echo "  dotfiles  — Shell + Git + Zed + Brew (standalone)"
    echo "  workspace — dotfiles + Claude Code + workspace config"
    echo "  mcp       — workspace + MCP servers + launchd + memory"
    echo "  doctor    — check an installed tier (default: mcp)"
    exit 1
    ;;
esac

echo ""
"$DOTFILES_DIR/doctor.sh" "$TIER" || true

[[ "$TIER" != "dotfiles" ]] && { "$DOTFILES_DIR/scripts/system/claude-handoff" || true; }

echo ""
exec zsh -l
