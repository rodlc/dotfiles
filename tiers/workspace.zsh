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

  # Bitwarden holds ~/.env (API tokens)
  echo "=====> Bitwarden secrets setup"
  RBW_CONFIG="$HOME/Library/Application Support/rbw/config.json"
  if [ ! -f "$RBW_CONFIG" ]; then
    echo ""
    echo "Bitwarden setup required for secrets (~/.env API tokens)."
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

  # Custom Raycast extensions (CCode Launcher, clipboard): launchd keeps them in ray develop (mcp tier)
  for ext in "$WORKSPACE_DIR"/raycast-extensions/*/; do
    if [[ -f "$ext/package-lock.json" && ! -d "$ext/node_modules" ]]; then
      echo "-----> Installing Raycast extension $(basename "$ext")"
      npm ci --prefix "$ext" --silent
    fi
  done

  if [[ ! -x "$HOME/.local/bin/rayclip" ]]; then
    echo "-----> Building rayclip"
    mkdir -p "$HOME/.local/bin"
    (cd "$WORKSPACE_DIR/tools/rayclip" && bun install --silent && bun run build)
  fi

  echo ""
  echo "✓ Tier workspace installed (Claude Code + workspace config)"
  echo ""
  echo "💡 To add MCP servers, run: ./install.sh mcp"
}
