#!/bin/bash
# === MCP Setup for new user sessions ===
# Usage: ./setup-mcp.sh
# Prérequis: Les MCPs doivent être buildés côté rodlecoent

set -e
DOTFILES="${DOTFILES:-$HOME/Code/rodlc/dotfiles}"
SOURCE_USER="rodlecoent"

echo "=== MCP Setup ==="

# 1. Créer symlinks vers les repos MCP
echo "Creating MCP symlinks..."
MCP_REPOS=(
  "mcp-memory-service"
  "mcp-notion-server"
  "Gmail-MCP-Server"
  "slack-mcp-server"
  "rails-mcp-server"
)

mkdir -p "$HOME/Code"
for repo in "${MCP_REPOS[@]}"; do
  if [ ! -L "$HOME/Code/$repo" ]; then
    ln -sf "/Users/$SOURCE_USER/Code/$repo" "$HOME/Code/$repo"
    echo "  ✓ $repo"
  fi
done

# 2. Gmail OAuth credentials
echo "Setting up Gmail MCP..."
mkdir -p ~/.gmail-mcp
if [ -f "$DOTFILES/claude/gmail-mcp/gcp-oauth.keys.json" ]; then
  ln -sf "$DOTFILES/claude/gmail-mcp/gcp-oauth.keys.json" ~/.gmail-mcp/
  echo "  ✓ OAuth credentials linked"
fi

# 3. Vérification des builds
echo ""
echo "=== Vérification des builds ==="
[ -d "$HOME/Code/rails-mcp-server/vendor/bundle" ] && echo "  ✓ Rails MCP: vendor/bundle OK" || echo "  ✗ Rails MCP: vendor/bundle MANQUANT"
[ -f "$HOME/Code/slack-mcp-server/build/slack-mcp-server" ] && echo "  ✓ Slack MCP: binary OK" || echo "  ✗ Slack MCP: binary MANQUANT"
[ -f "$HOME/Code/Gmail-MCP-Server/dist/index.js" ] && echo "  ✓ Gmail MCP: dist/ OK" || echo "  ✗ Gmail MCP: dist/ MANQUANT"
[ -d "$HOME/Code/mcp-notion-server/build" ] && echo "  ✓ Notion MCP: build/ OK" || echo "  ✗ Notion MCP: build/ MANQUANT"

echo ""
echo "Si des builds manquent, les exécuter côté $SOURCE_USER :"
echo "  Rails:  cd ~/Code/rails-mcp-server && bundle config set --local path vendor/bundle && bundle install"
echo "  Slack:  cd ~/Code/slack-mcp-server && make build"
echo ""
echo "Puis copier les tokens Gmail (sudo requis) :"
echo "  sudo cp -r /Users/$SOURCE_USER/.gmail-mcp/* ~/.gmail-mcp/"
echo "  sudo chown -R \$(whoami):staff ~/.gmail-mcp/"
echo ""
echo "Restart terminal and run 'claude' puis '/mcp' pour vérifier."
