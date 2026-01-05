#!/bin/bash
# === MCP Setup for new machines or users ===
# Usage: ./setup-mcp.sh
# Clones MCP repos from GitHub and provides build instructions

set -e

MCP_REPOS=(
  "mcp-memory-service:git@github.com:dosuken123/mcp-memory-service.git"
  "mcp-notion-server:git@github.com:makenotion/notion-mcp-server.git"
  "Gmail-MCP-Server:git@github.com:GongRzhe/Gmail-MCP-Server.git"
  "slack-mcp-server:git@github.com:nicholasgriffintn/slack-mcp-server.git"
  "rails-mcp-server:git@github.com:maquina-app/rails-mcp-server.git"
)

echo "=== MCP Setup ==="
echo ""

# Clone repos if missing
mkdir -p "$HOME/Code"
for entry in "${MCP_REPOS[@]}"; do
  repo="${entry%%:*}"
  url="${entry#*:}"
  if [ ! -d "$HOME/Code/$repo" ]; then
    echo "Cloning $repo..."
    git clone "$url" "$HOME/Code/$repo"
  else
    echo "✓ $repo already exists"
  fi
done

# Build instructions
echo ""
echo "=== Build MCP servers ==="
echo "Run these commands to build each MCP:"
echo ""
echo "  Rails:   cd ~/Code/rails-mcp-server && bundle config set --local path vendor/bundle && bundle install"
echo "  Slack:   cd ~/Code/slack-mcp-server && make build"
echo "  Gmail:   cd ~/Code/Gmail-MCP-Server && npm install && npm run build"
echo "  Notion:  cd ~/Code/mcp-notion-server && npm install && npm run build"
echo "  Memory:  cd ~/Code/mcp-memory-service && uv pip install -e ."
echo ""

# Verification
echo "=== Status ==="
[ -d "$HOME/Code/rails-mcp-server/vendor/bundle" ] && echo "  ✓ Rails MCP: vendor/bundle OK" || echo "  ✗ Rails MCP: vendor/bundle MANQUANT (run build)"
[ -f "$HOME/Code/slack-mcp-server/build/slack-mcp-server" ] && echo "  ✓ Slack MCP: binary OK" || echo "  ✗ Slack MCP: binary MANQUANT (run build)"
[ -f "$HOME/Code/Gmail-MCP-Server/dist/index.js" ] && echo "  ✓ Gmail MCP: dist/ OK" || echo "  ✗ Gmail MCP: dist/ MANQUANT (run build)"
[ -d "$HOME/Code/mcp-notion-server/build" ] && echo "  ✓ Notion MCP: build/ OK" || echo "  ✗ Notion MCP: build/ MANQUANT (run build)"

echo ""
echo "=== Next steps ==="
echo "1. Build missing MCPs using commands above"
echo "2. Configure Gmail OAuth credentials in ~/.gmail-mcp-* directories"
echo "3. Add MCP servers to ~/.claude.json or use 'claude mcp add'"
echo "4. Restart terminal and run 'claude' puis '/mcp' pour vérifier"
