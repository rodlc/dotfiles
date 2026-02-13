#!/bin/zsh
set -e

DOTFILES_DIR="$PWD"

echo "=====> Installing dotfiles"

# Helper functions
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

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
  echo "=====> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "=====> Homebrew already installed"
fi

# Fix Homebrew permissions for multi-user setup
if [[ -f "$DOTFILES_DIR/scripts/brew-fix-permissions" ]]; then
    "$DOTFILES_DIR/scripts/brew-fix-permissions"
fi

# Install Homebrew packages
echo "=====> Installing Homebrew packages"
brew install --quiet pyenv rbenv nvm git pre-commit rbw bitwarden-cli 2>/dev/null || true
brew install --cask --quiet zed battery 2>/dev/null || true

# Battery configuration (Apple Silicon only)
if [[ $(uname -m) == "arm64" ]] && command -v battery &> /dev/null; then
  echo "=====> Configuring Battery (charge limit)"
  # Set 80% charge limit if not already configured
  if [ ! -f "$HOME/.battery/maintain.percentage" ]; then
    echo "-----> Opening Battery app for initial setup (enter admin password when prompted)"
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
  echo ""
fi

# Install oh-my-zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "=====> Installing oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "=====> oh-my-zsh already installed"
fi

# Install Claude Code if not present
if ! command -v claude &> /dev/null; then
  echo "=====> Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "=====> Claude Code already installed"
fi

# Bitwarden setup (secrets + SSH key)
echo "=====> Bitwarden secrets setup"

# Configure rbw if not already done
RBW_CONFIG="$HOME/Library/Application Support/rbw/config.json"
if [ ! -f "$RBW_CONFIG" ]; then
    echo ""
    echo "Bitwarden setup required for secrets (SSH key, API tokens)."
    echo ""
    read -p "Enter your Bitwarden email (or press Enter to skip): " bw_email

    if [[ -n "$bw_email" ]]; then
        rbw config set email "$bw_email"
        rbw config set base_url https://api.bitwarden.eu/
        echo "-----> Registering with Bitwarden..."
        rbw register
    else
        echo "⚠️  Skipping Bitwarden. You can run install.sh again later."
    fi
fi

# Unlock and sync if configured
if [ -f "$RBW_CONFIG" ]; then
    if ! rbw unlocked 2>/dev/null; then
        echo "-----> Unlocking vault..."
        rbw unlock
    fi

    if rbw unlocked 2>/dev/null; then
        echo "-----> Syncing secrets from Bitwarden..."
        "$DOTFILES_DIR/scripts/bw-pull"
    fi
fi

# Ensure ~/.env exists (even if Bitwarden skipped)
if [ ! -f "$HOME/.env" ]; then
    echo "-----> Creating minimal ~/.env"
    touch "$HOME/.env"
    chmod 600 "$HOME/.env"
    echo ""
    echo "💡 To sync secrets later, run: bw-pull"
    echo ""
fi

# Restore zsh history from workspace if available
WORKSPACE_HISTORY="$HOME/Code/rodlc/workspace/shell/zsh_history"
if [[ -f "$WORKSPACE_HISTORY" && ! -f "$HOME/.zsh_history" ]]; then
    cp "$WORKSPACE_HISTORY" "$HOME/.zsh_history"
    echo "✅ zsh_history restored from workspace"
elif [[ -f "$WORKSPACE_HISTORY" && -f "$HOME/.zsh_history" ]]; then
    echo "✅ zsh_history already exists"
fi

echo "=====> Creating symlinks"

# Shell config
for name in aliases gitconfig irbrc pryrc rspec zprofile zshrc; do
  backup "$HOME/.$name"
  symlink "$DOTFILES_DIR/$name" "$HOME/.$name"
done

# Zsh plugins
ZSH_PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$ZSH_PLUGINS_DIR"
[ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
[ ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"

# SSH
backup "$HOME/.ssh/config"
symlink "$DOTFILES_DIR/config" "$HOME/.ssh/config"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519 2>/dev/null || true

# Zed
ZED_DIR="$HOME/.config/zed"
mkdir -p "$ZED_DIR"
backup "$ZED_DIR/settings.json"
symlink "$DOTFILES_DIR/zed/settings.json" "$ZED_DIR/settings.json"
backup "$ZED_DIR/keymap.json"
symlink "$DOTFILES_DIR/zed/keymap.json" "$ZED_DIR/keymap.json"

# Zsh modular config + Starship
ZSH_CONFIG_DIR="$HOME/.config/zsh"
mkdir -p "$ZSH_CONFIG_DIR/conf.d"
backup "$ZSH_CONFIG_DIR/.zsh_plugins.txt"
symlink "$DOTFILES_DIR/zsh/.zsh_plugins.txt" "$ZSH_CONFIG_DIR/.zsh_plugins.txt"
for conf in "$DOTFILES_DIR/zsh/conf.d"/*.zsh; do
  backup "$ZSH_CONFIG_DIR/conf.d/$(basename "$conf")"
  symlink "$conf" "$ZSH_CONFIG_DIR/conf.d/$(basename "$conf")"
done
backup "$HOME/.config/starship.toml"
symlink "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# Finicky
backup "$HOME/.finicky.js"
symlink "$DOTFILES_DIR/finicky.js" "$HOME/.finicky.js"

# Terminal profile
TERMINAL_PROFILE="$DOTFILES_DIR/terminal/Pro Nord.terminal"
if [ -f "$TERMINAL_PROFILE" ]; then
  echo "=====> Importing Terminal profile"
  open "$TERMINAL_PROFILE"
  sleep 1
  defaults write com.apple.Terminal "Default Window Settings" -string "Pro Nord"
  defaults write com.apple.Terminal "Startup Window Settings" -string "Pro Nord"
fi

# Claude Code
mkdir -p "$HOME/.claude/commands" "$HOME/.claude/hooks" "$HOME/.claude/skills"
backup "$HOME/.claude/CLAUDE.md"
symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Claude commands (all .md files)
for cmd in "$DOTFILES_DIR/claude/commands"/*.md; do
  [ -f "$cmd" ] || continue
  backup "$HOME/.claude/commands/$(basename "$cmd")"
  symlink "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
done

# Claude hooks - basic hooks only (mcp-memory-service hooks installed separately)
backup "$HOME/.claude/hooks/safe-bash.sh"
symlink "$DOTFILES_DIR/claude/hooks/safe-bash.sh" "$HOME/.claude/hooks/safe-bash.sh"
backup "$HOME/.claude/hooks/auto-approve-skills.sh"
symlink "$DOTFILES_DIR/claude/hooks/auto-approve-skills.sh" "$HOME/.claude/hooks/auto-approve-skills.sh"

# Note: session-init.sh and user-prompt-context.sh are replaced by mcp-memory-service hooks
# These will be installed via install_hooks.py below
if [ -d "$DOTFILES_DIR/claude/skills/terminal-title" ]; then
  symlink "$DOTFILES_DIR/claude/skills/terminal-title" "$HOME/.claude/skills/terminal-title"
fi
backup "$HOME/.claude/statusline.sh"
symlink "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
backup "$HOME/.claude/settings.json"
symlink "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"

# Agent docs (reference documentation)
symlink "$DOTFILES_DIR/claude/agent_docs" "$HOME/.claude/agent_docs"

# Install MCP servers config
if [ -x "$DOTFILES_DIR/claude/mcp-sync.sh" ]; then
  "$DOTFILES_DIR/claude/mcp-sync.sh" install
else
  echo "Warning: mcp-sync.sh not found or not executable"
fi

# Install pre-commit hooks (Gitleaks)
if [ -f "$DOTFILES_DIR/.pre-commit-config.yaml" ]; then
  echo "=====> Installing pre-commit hooks"
  pre-commit install
else
  echo "Warning: .pre-commit-config.yaml not found"
fi

# Install global git hook (dotfiles reminder)
GLOBAL_HOOKS_DIR="$HOME/.git-templates/hooks"
mkdir -p "$GLOBAL_HOOKS_DIR"
if [ -f "$DOTFILES_DIR/.git-hooks/pre-commit" ]; then
  echo "=====> Installing global dotfiles reminder hook"
  cp "$DOTFILES_DIR/.git-hooks/pre-commit" "$GLOBAL_HOOKS_DIR/pre-commit"
  chmod +x "$GLOBAL_HOOKS_DIR/pre-commit"
  git config --global init.templatedir "$HOME/.git-templates"
else
  echo "Warning: .git-hooks/pre-commit not found"
fi

# Install mcp-memory-service HTTP server (launchd)
echo "=====> Installing mcp-memory-service HTTP server"
MCP_MEMORY_SERVICE="$HOME/Code/rodlc/workspace/mcp-servers/mcp-memory-service"

if [ -d "$MCP_MEMORY_SERVICE" ]; then
  # Install launchd plist
  mkdir -p "$HOME/Library/LaunchAgents"
  backup "$HOME/Library/LaunchAgents/com.rodlecoent.mcp-memory-http.plist"
  cp "$DOTFILES_DIR/launchd/com.rodlecoent.mcp-memory-http.plist" "$HOME/Library/LaunchAgents/com.rodlecoent.mcp-memory-http.plist"

  # Make startup script executable
  chmod +x "$DOTFILES_DIR/scripts/mcp-memory-http-start.sh"

  # Load the service
  launchctl unload "$HOME/Library/LaunchAgents/com.rodlecoent.mcp-memory-http.plist" 2>/dev/null || true
  launchctl load "$HOME/Library/LaunchAgents/com.rodlecoent.mcp-memory-http.plist"

  echo "-----> HTTP server service installed and loaded"
  echo "-----> Waiting 5 seconds for server to start..."
  sleep 5

  # Verify server is running (port 4242)
  if curl -s --max-time 2 http://127.0.0.1:4242/api/health > /dev/null 2>&1; then
    echo "-----> ✓ HTTP server is running on port 4242"
  else
    echo "-----> ⚠️  HTTP server not responding (check logs: ~/Library/Logs/mcp-memory-http.log)"
  fi

  # Install mcp-memory-service hooks
  echo "=====> Installing mcp-memory-service hooks"
  if [ -f "$MCP_MEMORY_SERVICE/claude-hooks/install_hooks.py" ]; then
    cd "$MCP_MEMORY_SERVICE/claude-hooks"
    python3 install_hooks.py --natural-triggers
    cd "$DOTFILES_DIR"
    echo "-----> Hooks installed with natural triggers"

    # Check if config.json needs API key
    HOOKS_CONFIG="$HOME/.claude/hooks/config.json"
    if [ -f "$HOOKS_CONFIG" ]; then
      if grep -q '"apiKey": ""' "$HOOKS_CONFIG" 2>/dev/null; then
        echo ""
        echo "💡 Generate an API key for hooks authentication:"
        echo "   export MCP_API_KEY=\"\$(openssl rand -base64 32)\""
        echo "   # Then add it to $HOME/.env and hooks config.json"
      fi
    fi
  else
    echo "-----> ⚠️  install_hooks.py not found, skipping hooks installation"
  fi
else
  echo "-----> ⚠️  mcp-memory-service not found at $MCP_MEMORY_SERVICE"
  echo "-----> Run workspace-install.sh first"
fi

echo ""
echo "✓ Dotfiles installed"
echo ""

# macOS defaults (optional, run once on fresh install)
if [[ "$OSTYPE" == "darwin"* ]]; then
    read -p "Configure macOS defaults? (Dock, Finder, keyboard...) [y/N] " macos_choice
    if [[ "$macos_choice" =~ ^[Yy]$ ]]; then
        bash "$DOTFILES_DIR/macos.sh"
    fi
fi

echo ""
echo "💡 To install workspace + MCP servers, run: ./workspace-install.sh"
echo ""

exec zsh
