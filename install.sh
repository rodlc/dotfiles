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
brew install --quiet pyenv rbenv nvm git pre-commit 2>/dev/null || true
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
backup "$HOME/.claude/skills/playwright.md"
symlink "$DOTFILES_DIR/claude/skills/playwright.md" "$HOME/.claude/skills/playwright.md"
backup "$HOME/.claude/statusline.sh"
symlink "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
backup "$HOME/.claude/settings.json"
cp "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json" 2>/dev/null && echo "-----> Copied settings.json" || true

# Install MCP server repositories
echo "=====> Installing MCP server repositories"
"$DOTFILES_DIR/claude/install-mcp-servers.sh"

# Install MCPs from dotfiles
echo "=====> Configuring MCP servers"
"$DOTFILES_DIR/claude/mcp-sync.sh" install

# Environment variables
if [ ! -f "$HOME/.env" ] && [ -f "$DOTFILES_DIR/.env.example" ]; then
  echo "=====> Creating ~/.env from .env.example"
  cp "$DOTFILES_DIR/.env.example" "$HOME/.env"
  echo "-----> Edit ~/.env with your API keys"
else
  echo "=====> ~/.env already exists (not overwriting)"
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

echo "✓ Done"
exec zsh
