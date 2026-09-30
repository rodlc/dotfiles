#!/bin/zsh
set -e

DOTFILES_DIR="$PWD"
TIER="${1:-dotfiles}"  # dotfiles | workspace | mcp

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

# ══════════════════════════════════════════════════════════════════
# Helpers
# ══════════════════════════════════════════════════════════════════

backup() {
  local target="$1"
  [ -e "$target" ] && [ ! -L "$target" ] && mv "$target" "$target.backup" && echo "-----> Backed up $target" || true
}

symlink() {
  local source="$1" link="$2"
  [ ! -e "$source" ] && echo "Warning: $source not found" && return 0

  # If symlink exists but points elsewhere, recreate it
  if [ -L "$link" ]; then
    local current=$(readlink "$link")
    if [ "$current" != "$source" ]; then
      rm "$link"
      echo "-----> Fixed $link (was: $current)"
    fi
  fi

  [ ! -e "$link" ] && ln -s "$source" "$link" && echo "-----> Linked $link" || true
}

generate_git_identities() {
  source "$HOME/.env" 2>/dev/null || true
  if [[ -n "${GIT_USER_NAME:-}" && -n "${GIT_USER_EMAIL:-}" ]]; then
    mkdir -p "$HOME/.config/git"
    cat > "$HOME/.config/git/config-identity" <<EOF
[user]
  email = $GIT_USER_EMAIL
  name = $GIT_USER_NAME
EOF
    echo "-----> Generated git identity"
  fi
  if [[ -n "${GIT_USER_EMAIL_MAGIC:-}" ]]; then
    mkdir -p "$HOME/.config/git"
    cat > "$HOME/.config/git/config-identity-magic" <<EOF
[user]
  email = $GIT_USER_EMAIL_MAGIC
  name = ${GIT_USER_NAME:-}
EOF
    echo "-----> Generated git identity (magic)"
  fi
}

# ══════════════════════════════════════════════════════════════════
# TIER: dotfiles — Shell + Git + Zed + Brew (standalone machine)
# ══════════════════════════════════════════════════════════════════

install_dotfiles() {
  # Homebrew
  if ! command -v brew &> /dev/null; then
    echo "=====> Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "=====> Homebrew already installed"
  fi

  if [[ -f "$DOTFILES_DIR/scripts/system/brew-fix-permissions" ]]; then
    "$DOTFILES_DIR/scripts/system/brew-fix-permissions"
  fi

  echo "=====> Installing Homebrew packages"
  # Homebrew 7 refuses formulae from untrusted taps
  brew tap rtk-ai/tap && brew trust --formula rtk-ai/tap/rtk
  brew bundle --file="$DOTFILES_DIR/Brewfile" || { echo "⚠️  Some brew packages failed to install"; }

  # mise runtimes
  echo "=====> Installing language runtimes"
  if command -v mise &>/dev/null; then
    echo "-----> Installing runtimes via mise"
    mise install
  else
    echo "⚠️  mise not found, skipping runtimes"
  fi

  echo "=====> Creating symlinks"

  # home/ → ~/.<name>
  for name in zshenv zprofile zshrc; do
    backup "$HOME/.$name"
    symlink "$DOTFILES_DIR/home/$name" "$HOME/.$name"
  done
  backup "$HOME/.irbrc"
  symlink "$DOTFILES_DIR/home/irbrc" "$HOME/.irbrc"
  backup "$HOME/.rspec"
  symlink "$DOTFILES_DIR/home/rspec" "$HOME/.rspec"
  backup "$HOME/.finicky.js"
  symlink "$DOTFILES_DIR/home/finicky.js" "$HOME/.finicky.js"
  mkdir -p "$HOME/.ssh"
  backup "$HOME/.ssh/config"
  symlink "$DOTFILES_DIR/home/ssh/config" "$HOME/.ssh/config"

  # config/ → ~/.config/<app>/
  mkdir -p "$HOME/.config/pry"
  symlink "$DOTFILES_DIR/config/pry/pryrc" "$HOME/.config/pry/pryrc"
  mkdir -p "$HOME/.config/git" "$HOME/.config/mise"
  symlink "$DOTFILES_DIR/config/mise/config.toml" "$HOME/.config/mise/config.toml"
  symlink "$DOTFILES_DIR/config/git/config" "$HOME/.config/git/config"
  mkdir -p "$HOME/.config/zsh"
  symlink "$DOTFILES_DIR/config/zsh/aliases" "$HOME/.config/zsh/aliases"

  # Git identity (generated from ~/.env if available)
  generate_git_identities

  # Zed
  ZED_DIR="$HOME/.config/zed"
  mkdir -p "$ZED_DIR"
  backup "$ZED_DIR/settings.json"
  symlink "$DOTFILES_DIR/config/zed/settings.json" "$ZED_DIR/settings.json"
  backup "$ZED_DIR/keymap.json"
  symlink "$DOTFILES_DIR/config/zed/keymap.json" "$ZED_DIR/keymap.json"

  # Zsh modular config + Starship
  ZSH_CONFIG_DIR="$HOME/.config/zsh"
  mkdir -p "$ZSH_CONFIG_DIR/conf.d"
  backup "$ZSH_CONFIG_DIR/.zsh_plugins.txt"
  symlink "$DOTFILES_DIR/config/zsh/.zsh_plugins.txt" "$ZSH_CONFIG_DIR/.zsh_plugins.txt"
  for conf in "$DOTFILES_DIR/config/zsh/conf.d"/*.zsh; do
    backup "$ZSH_CONFIG_DIR/conf.d/$(basename "$conf")"
    symlink "$conf" "$ZSH_CONFIG_DIR/conf.d/$(basename "$conf")"
  done
  backup "$HOME/.config/starship.toml"
  symlink "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"

  # Terminal profile
  TERMINAL_PROFILE="$DOTFILES_DIR/terminal/Pro Nord.terminal"
  if [ -f "$TERMINAL_PROFILE" ]; then
    # Terminal rewrites its prefs on quit, so defaults write is lost when run from Terminal itself
    CURRENT_DEFAULT=$(osascript -e 'tell application "Terminal" to get name of default settings' 2>/dev/null || echo "")
    if [[ "$CURRENT_DEFAULT" != "Pro Nord" ]]; then
      echo "=====> Importing Terminal profile"
      open "$TERMINAL_PROFILE"
      sleep 1
      osascript -e 'tell application "Terminal" to set default settings to settings set "Pro Nord"' \
                -e 'tell application "Terminal" to set startup settings to settings set "Pro Nord"'
    fi
  fi

  # Pre-commit hooks (Gitleaks)
  if [ -f "$DOTFILES_DIR/.pre-commit-config.yaml" ]; then
    if command -v pre-commit &>/dev/null; then
      echo "=====> Installing pre-commit hooks"
      pre-commit install
    else
      echo "⚠️  pre-commit not found, skipping hooks"
    fi
  fi

  # Global git hook (dotfiles reminder)
  GLOBAL_HOOKS_DIR="$HOME/.git-templates/hooks"
  mkdir -p "$GLOBAL_HOOKS_DIR"
  if [ -f "$DOTFILES_DIR/.git-hooks/pre-commit" ]; then
    echo "=====> Installing global dotfiles reminder hook"
    cp "$DOTFILES_DIR/.git-hooks/pre-commit" "$GLOBAL_HOOKS_DIR/pre-commit"
    chmod +x "$GLOBAL_HOOKS_DIR/pre-commit"
    # init.templatedir is versioned in config/git/config; git config --global would rewrite that tracked file
  fi

  echo ""
  echo "✓ Tier dotfiles installed (shell, git, zed, brew)"

  # macOS defaults (optional)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    read "macos_choice?Configure macOS defaults? (Dock, Finder, keyboard...) [y/N] "
    if [[ "$macos_choice" =~ ^[Yy]$ ]]; then
      zsh "$DOTFILES_DIR/macos.sh"
    fi
  fi
}

# ══════════════════════════════════════════════════════════════════
# TIER: workspace — dotfiles + Claude Code + workspace config
# ══════════════════════════════════════════════════════════════════

install_workspace() {
  # Install Claude Code CLI (mise pins claude-code in config/mise/config.toml)
  if command -v mise &>/dev/null && mise which claude &>/dev/null; then
    echo "=====> Claude Code provided by mise"
  elif ! command -v claude &> /dev/null; then
    echo "=====> Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
  else
    echo "=====> Claude Code already installed"
  fi

  # Bitwarden setup (SSH key needed to clone workspace)
  echo "=====> Bitwarden secrets setup"
  RBW_CONFIG="$HOME/Library/Application Support/rbw/config.json"
  if [ ! -f "$RBW_CONFIG" ]; then
    echo ""
    echo "Bitwarden setup required for secrets (SSH key, API tokens)."
    echo ""
    read "bw_email?Enter your Bitwarden email (or press Enter to skip): "
    if [[ -n "$bw_email" ]]; then
      rbw config set email "$bw_email"
      rbw config set base_url https://api.bitwarden.eu/
      rbw config set pinentry pinentry-mac
      echo "-----> Registering with Bitwarden..."
      # A failed register leaves config.json, which would skip this block on rerun
      rbw register || { rm -f "$RBW_CONFIG"; echo "⚠️  rbw register failed, rerun install.sh workspace"; exit 1; }
    else
      echo "⚠️  Skipping Bitwarden. You can run install.sh workspace again later."
    fi
  fi

  if [ -f "$RBW_CONFIG" ]; then
    if rbw unlocked 2>/dev/null; then
      echo "-----> Syncing secrets from Bitwarden..."
      "$DOTFILES_DIR/scripts/code/bw-pull"
    elif [ ! -f "$HOME/.env" ]; then
      echo "-----> Unlocking vault (~/.env missing)..."
      rbw unlock && "$DOTFILES_DIR/scripts/code/bw-pull"
    else
      echo "-----> Bitwarden vault locked — skipping sync. Run 'bw-pull' to force refresh."
    fi
  fi

  # Ensure ~/.env exists
  if [ ! -f "$HOME/.env" ]; then
    echo "-----> Creating minimal ~/.env"
    touch "$HOME/.env"
    chmod 600 "$HOME/.env"
  fi

  # Re-generate git identity now that ~/.env may have been populated
  generate_git_identities

  # GitHub over HTTPS: one gh token per machine, revocable alone, no SSH key
  if ! gh auth token &>/dev/null; then
    echo "=====> GitHub login (HTTPS, browser)"
    gh auth login -h github.com -p https -w
  fi

  # Clone workspace if not present
  WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
  if [ ! -d "$WORKSPACE_DIR" ]; then
    if gh auth token &>/dev/null; then
      echo "-----> Cloning workspace repository"
      mkdir -p "$(dirname "$WORKSPACE_DIR")"
      git clone --recurse-submodules https://github.com/rodlc/workspace.git "$WORKSPACE_DIR"
    else
      echo "⚠️  GitHub not authenticated. Run install.sh workspace again after gh auth login."
      return 0
    fi
  else
    echo "-----> Workspace already exists, updating submodules..."
    git -C "$WORKSPACE_DIR" submodule update --init --recursive --quiet
  fi

  # Add WORKSPACE_DIR to ~/.env if not present
  if ! grep -q "^export WORKSPACE_DIR=" "$HOME/.env" 2>/dev/null; then
    echo "export WORKSPACE_DIR=\"$WORKSPACE_DIR\"" >> "$HOME/.env"
    echo "-----> Added WORKSPACE_DIR to ~/.env"
  fi

  # Symlink Claude config from workspace → ~/.claude/
  echo "=====> Linking Claude Code config from workspace"
  "$WORKSPACE_DIR/claude-config/scripts/sync-claude-symlinks.sh" --install

  # Restore zsh history from workspace
  WORKSPACE_HISTORY="$WORKSPACE_DIR/shell/zsh_history"
  ZSH_HISTORY="$HOME/.local/state/zsh/history"
  mkdir -p "$HOME/.local/state/zsh"
  if [[ -f "$HOME/.zsh_history" && ! -f "$ZSH_HISTORY" ]]; then
    mv "$HOME/.zsh_history" "$ZSH_HISTORY"
    echo "-----> Migrated .zsh_history to $ZSH_HISTORY"
  fi
  if [[ -f "$WORKSPACE_HISTORY" && ! -f "$ZSH_HISTORY" ]]; then
    cp "$WORKSPACE_HISTORY" "$ZSH_HISTORY"
    echo "-----> zsh_history restored from workspace"
  elif [[ -f "$ZSH_HISTORY" ]]; then
    echo "-----> zsh_history already exists"
  fi

  echo ""
  echo "✓ Tier workspace installed (Claude Code + workspace config)"
  echo ""
  echo "💡 To add MCP servers, run: ./install.sh mcp"
}

# ══════════════════════════════════════════════════════════════════
# TIER: mcp — workspace + MCP servers + launchd + memory
# ══════════════════════════════════════════════════════════════════

install_mcp() {
  WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
  source "$HOME/.env" 2>/dev/null || true

  # Verify workspace exists
  if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "⚠️  Workspace not found. Run: ./install.sh workspace"
    return 1
  fi

  # Build MCP servers
  echo "=====> Building MCP servers"
  if [ -x "$WORKSPACE_DIR/claude-config/scripts/install-mcp-servers.sh" ]; then
    "$WORKSPACE_DIR/claude-config/scripts/install-mcp-servers.sh"
  else
    echo "⚠️  install-mcp-servers.sh not found in workspace"
  fi

  # Configure MCPs (expand template → ~/.claude.json)
  echo "=====> Configuring MCP servers"
  if [ -x "$WORKSPACE_DIR/claude-config/scripts/mcp-sync.sh" ]; then
    "$WORKSPACE_DIR/claude-config/scripts/mcp-sync.sh" install
  fi

  # Launchd services (MCP memory + backup)
  echo "=====> Installing launchd services"
  MCP_MEMORY_SERVICE="$WORKSPACE_DIR/mcp-servers/mcp-memory-service"

  if [ -d "$MCP_MEMORY_SERVICE" ]; then
    mkdir -p "$HOME/Library/LaunchAgents"

    LAUNCHD_SRC="$WORKSPACE_DIR/claude-config/launchd"
    if [ -d "$LAUNCHD_SRC" ]; then
      for plist in "$LAUNCHD_SRC"/*.plist; do
        [ -f "$plist" ] || continue
        local name="$(basename "$plist")"
        backup "$HOME/Library/LaunchAgents/$name"
        sed "s|__HOME__|$HOME|g" "$plist" > "$HOME/Library/LaunchAgents/$name"

        local label="${name%.plist}"
        launchctl unload "$HOME/Library/LaunchAgents/$name" 2>/dev/null || true
        launchctl load "$HOME/Library/LaunchAgents/$name" 2>/dev/null || true
      done
      echo "-----> Launchd services installed and loaded"
    fi

    # Wait for memory server
    echo "-----> Waiting for memory server..."
    sleep 5
    if curl -s --max-time 2 http://127.0.0.1:4242/api/health > /dev/null 2>&1; then
      echo "-----> ✓ HTTP server running on port 4242"
    else
      echo "-----> ⚠️  HTTP server not responding (check: ~/Library/Logs/mcp-memory-http.log)"
    fi

    # Memory hooks
    echo "=====> Installing mcp-memory-service hooks"
    if [ -f "$MCP_MEMORY_SERVICE/claude-hooks/install_hooks.py" ]; then
      cd "$MCP_MEMORY_SERVICE/claude-hooks"
      python3 install_hooks.py --natural-triggers
      cd "$DOTFILES_DIR"
      echo "-----> Hooks installed with natural triggers"

      HOOKS_CONFIG="$HOME/.claude/hooks/config.json"
      if [ -f "$HOOKS_CONFIG" ] && grep -q '"apiKey": ""' "$HOOKS_CONFIG" 2>/dev/null; then
        echo ""
        echo "💡 Generate an API key for hooks authentication:"
        echo "   export MCP_API_KEY=\"\$(openssl rand -base64 32)\""
        echo "   # Then add it to \$HOME/.env and hooks config.json"
      fi
    fi
  else
    echo "-----> ⚠️  mcp-memory-service not found, skipping launchd setup"
  fi

  # Ollama
  if command -v ollama &>/dev/null; then
    echo "=====> Configuring Ollama"
    for model in qwen3:4b; do
      if ! ollama list 2>/dev/null | grep -q "$model"; then
        echo "-----> Pulling $model..."
        ollama pull "$model"
      else
        echo "-----> $model already present"
      fi
    done
  fi

  # Battery (Apple Silicon only)
  if [[ $(uname -m) == "arm64" ]] && command -v battery &> /dev/null; then
    echo "=====> Configuring Battery (charge limit)"
    if [ ! -f "$HOME/.battery/maintain.percentage" ]; then
      echo "-----> Opening Battery app for initial setup"
      open -a battery
      sleep 3
      echo "-----> Setting charge limit to 80%"
      battery maintain 15-85 2>/dev/null || true
    else
      echo "-----> Battery already configured"
    fi
    echo ""
    echo "💡 Run 'battery visudo' manually for sudo-free operation"
    echo "💡 Disable 'Optimized Battery Charging' in System Settings > Battery"
  fi

  echo ""
  echo "✓ Tier mcp installed (MCP servers + launchd + memory)"
}

# ══════════════════════════════════════════════════════════════════
# Main — run tiers progressively
# ══════════════════════════════════════════════════════════════════

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
    echo "Usage: ./install.sh [dotfiles|workspace|mcp]"
    echo "  dotfiles  — Shell + Git + Zed + Brew (standalone)"
    echo "  workspace — dotfiles + Claude Code + workspace config"
    echo "  mcp       — workspace + MCP servers + launchd + memory"
    exit 1
    ;;
esac

[[ "$TIER" != "dotfiles" ]] && { "$DOTFILES_DIR/scripts/system/claude-handoff" || true; }

echo ""
exec zsh -l
