#!/bin/zsh
set -e

DOTFILES_DIR="$PWD"

backup() {
  local target="$1"
  [ -e "$target" ] && [ ! -L "$target" ] && mv "$target" "$target.backup" && echo "-----> Backed up $target"
}

symlink() {
  local source="$1" link="$2"
  [ ! -e "$source" ] && echo "Warning: $source not found" && return
  [ ! -e "$link" ] && ln -s "$source" "$link" && echo "-----> Linked $link"
}

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
mkdir -p "$HOME/.claude/commands"
backup "$HOME/.claude/CLAUDE.md"
symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
backup "$HOME/.claude/commands/notion.md"
symlink "$DOTFILES_DIR/claude/commands/notion.md" "$HOME/.claude/commands/notion.md"

echo "✓ Done"
exec zsh
