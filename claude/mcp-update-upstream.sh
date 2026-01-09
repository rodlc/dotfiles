#!/bin/bash
# Update MCP from upstream and sync to workspace
set -e

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
MCP_DIR="$WORKSPACE_DIR/mcp-servers"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS] <mcp-name>

Update an MCP fork from upstream and sync to workspace.

OPTIONS:
  -l, --list      List all MCPs with upstream status
  -c, --check     Check for upstream updates without merging
  -h, --help      Show this help message

EXAMPLES:
  # List all MCPs
  $(basename "$0") --list

  # Check updates for notion MCP
  $(basename "$0") --check mcp-notion-server

  # Update notion MCP from upstream
  $(basename "$0") mcp-notion-server

MCP NAMES:
  mcp-notion-server, slack-mcp-server, google-calendar-mcp, mcp-memory-service
EOF
}

list_mcps() {
  echo -e "${BLUE}=====> MCPs with upstream configured${NC}"
  echo ""

  cd "$WORKSPACE_DIR"
  git submodule foreach --quiet '
    if git remote get-url upstream &>/dev/null; then
      name=$(basename $(pwd))
      upstream=$(git remote get-url upstream)
      behind=$(git rev-list HEAD..upstream/main --count 2>/dev/null || echo "?")

      if [[ "$behind" == "0" ]]; then
        status="✓ up to date"
      elif [[ "$behind" == "?" ]]; then
        status="? (fetch required)"
      else
        status="⬆️  $behind commits behind"
      fi

      printf "%-25s %s\n" "$name" "$status"
      printf "  upstream: %s\n\n" "$upstream"
    fi
  '
}

check_updates() {
  local mcp_name="$1"
  local mcp_path="$MCP_DIR/$mcp_name"

  if [ ! -d "$mcp_path" ]; then
    echo -e "${RED}Error: MCP '$mcp_name' not found in $MCP_DIR${NC}"
    exit 1
  fi

  cd "$mcp_path"

  if ! git remote get-url upstream &>/dev/null; then
    echo -e "${YELLOW}Warning: No upstream remote configured for $mcp_name${NC}"
    echo "Run 'install-mcp-servers.sh' to configure upstream remotes"
    exit 1
  fi

  echo -e "${BLUE}=====> Checking upstream for $mcp_name${NC}"
  git fetch upstream --quiet

  local upstream_branch=$(git remote show upstream 2>/dev/null | grep "HEAD branch" | cut -d" " -f5)
  [[ -z "$upstream_branch" ]] && upstream_branch="main"

  local behind=$(git rev-list HEAD..upstream/$upstream_branch --count 2>/dev/null)

  if [[ "$behind" == "0" ]]; then
    echo -e "${GREEN}✓ Already up to date with upstream${NC}"
    exit 0
  fi

  echo -e "${YELLOW}⬆️  $behind commits behind upstream/$upstream_branch${NC}"
  echo ""
  echo "Recent upstream commits:"
  git log HEAD..upstream/$upstream_branch --oneline --max-count=5
}

update_mcp() {
  local mcp_name="$1"
  local mcp_path="$MCP_DIR/$mcp_name"

  if [ ! -d "$mcp_path" ]; then
    echo -e "${RED}Error: MCP '$mcp_name' not found in $MCP_DIR${NC}"
    exit 1
  fi

  cd "$mcp_path"

  if ! git remote get-url upstream &>/dev/null; then
    echo -e "${YELLOW}Warning: No upstream remote configured for $mcp_name${NC}"
    echo "Run 'install-mcp-servers.sh' to configure upstream remotes"
    exit 1
  fi

  echo -e "${BLUE}=====> Updating $mcp_name from upstream${NC}"

  # 1. Fetch upstream
  echo "-----> Fetching upstream..."
  git fetch upstream --quiet

  local upstream_branch=$(git remote show upstream 2>/dev/null | grep "HEAD branch" | cut -d" " -f5)
  [[ -z "$upstream_branch" ]] && upstream_branch="main"

  local behind=$(git rev-list HEAD..upstream/$upstream_branch --count 2>/dev/null)

  if [[ "$behind" == "0" ]]; then
    echo -e "${GREEN}✓ Already up to date with upstream${NC}"
    return 0
  fi

  echo -e "${YELLOW}⬆️  $behind commits to merge from upstream/$upstream_branch${NC}"
  echo ""
  git log HEAD..upstream/$upstream_branch --oneline --max-count=10
  echo ""

  # 2. Confirm merge
  read -p "Merge these changes? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 0
  fi

  # 3. Merge upstream
  echo "-----> Merging upstream/$upstream_branch..."
  if git merge upstream/$upstream_branch --no-edit; then
    echo -e "${GREEN}✓ Merged successfully${NC}"
  else
    echo -e "${RED}✗ Merge conflict! Resolve manually and run:${NC}"
    echo "  cd $mcp_path"
    echo "  git merge --continue"
    echo "  git push origin main"
    exit 1
  fi

  # 4. Push to fork
  echo "-----> Pushing to fork (origin)..."
  git push origin main
  echo -e "${GREEN}✓ Pushed to fork${NC}"

  # 5. Update workspace submodule reference
  echo "-----> Updating workspace submodule reference..."
  cd "$WORKSPACE_DIR"
  git add "mcp-servers/$mcp_name"
  git commit -m "Update $mcp_name to sync with upstream

Merged upstream changes ($behind commits)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

  echo -e "${GREEN}✓ Workspace updated${NC}"

  # 6. Rebuild MCP
  echo "-----> Rebuilding MCP..."
  ~/Code/rodlc/dotfiles/claude/install-mcp-servers.sh > /dev/null 2>&1

  echo ""
  echo -e "${GREEN}✓ Update complete!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Push workspace: cd $WORKSPACE_DIR && git push"
  echo "2. Restart Claude: claude-restart"
}

# Parse arguments
case "${1:-}" in
  -l|--list)
    list_mcps
    exit 0
    ;;
  -c|--check)
    if [ -z "${2:-}" ]; then
      echo "Error: MCP name required"
      usage
      exit 1
    fi
    check_updates "$2"
    exit 0
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  "")
    usage
    exit 1
    ;;
  *)
    update_mcp "$1"
    ;;
esac
