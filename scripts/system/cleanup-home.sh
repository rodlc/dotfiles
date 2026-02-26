#!/bin/bash
# cleanup-home.sh — Remove known cruft from home directory
set -euo pipefail

echo "🧹 Cleaning up home directory cruft..."

CRUFT=(
    "$HOME/bin"                     # Vide
    "$HOME/go"                      # Cache Go pkg (goenv gère son GOPATH)
    "$HOME/.gmail-mcp"              # Ancien dir (remplacé par gmail-mcp-rodlecoent)
    "$HOME/.profile"                # Non utilisé (zsh)
    "$HOME/.mcp.json"               # Doublon racine (le vrai est dans ~/.claude/)
    "$HOME/.cursor"                 # Cursor IDE non utilisé (2.8 GB)
    "$HOME/.lesshst"                # Historique less
    "$HOME/.zshrc.pre-oh-my-zsh"    # Cruft oh-my-zsh
    "$HOME/.zshrc.backup."*         # Vieux backups
    "$HOME/.env.backup."*           # Vieux backups
    "$HOME/.claude.json.backup"*    # Backups mcp-sync orphelins
)

for item in "${CRUFT[@]}"; do
    if [[ -e "$item" ]]; then
        size=$(du -sh "$item" 2>/dev/null | awk '{print $1}')
        echo "  ✗ $item ($size)"
    fi
done

echo ""
read -p "Delete all listed items? [y/N] " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    for item in "${CRUFT[@]}"; do
        [[ -e "$item" ]] && rm -rf "$item" && echo "  🗑  $item"
    done
    echo "✅ Cleanup done"
else
    echo "⏭️  Skipped"
fi
