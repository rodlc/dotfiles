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

# Install Homebrew packages
echo "=====> Installing Homebrew packages"
brew install --quiet pyenv rbenv nvm git pre-commit rbw bitwarden-cli 2>/dev/null || true
brew install --cask --quiet zed 2>/dev/null || true

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

# Claude Code
mkdir -p "$HOME/.claude/commands" "$HOME/.claude/hooks" "$HOME/.claude/skills"
backup "$HOME/.claude/CLAUDE.md"
symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
backup "$HOME/.claude/commands/notion.md"
symlink "$DOTFILES_DIR/claude/commands/notion.md" "$HOME/.claude/commands/notion.md"
backup "$HOME/.claude/commands/summarize.md"
symlink "$DOTFILES_DIR/claude/commands/summarize.md" "$HOME/.claude/commands/summarize.md"
backup "$HOME/.claude/hooks/safe-bash.sh"
symlink "$DOTFILES_DIR/claude/hooks/safe-bash.sh" "$HOME/.claude/hooks/safe-bash.sh"
backup "$HOME/.claude/hooks/auto-approve-skills.sh"
symlink "$DOTFILES_DIR/claude/hooks/auto-approve-skills.sh" "$HOME/.claude/hooks/auto-approve-skills.sh"
backup "$HOME/.claude/hooks/session-init.sh"
symlink "$DOTFILES_DIR/claude/hooks/session-init.sh" "$HOME/.claude/hooks/session-init.sh"
if [ -d "$DOTFILES_DIR/claude/skills/terminal-title" ]; then
  symlink "$DOTFILES_DIR/claude/skills/terminal-title" "$HOME/.claude/skills/terminal-title"
fi
backup "$HOME/.claude/statusline.sh"
symlink "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
backup "$HOME/.claude/settings.json"
cp "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json" 2>/dev/null && echo "-----> Copied settings.json" || true

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

echo ""
echo "✓ Dotfiles installed"
echo ""
echo "💡 To install workspace + MCP servers, run: ./workspace-install.sh"
echo ""

exec zsh
