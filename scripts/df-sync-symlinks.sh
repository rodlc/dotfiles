#!/bin/zsh
# Sync symlinks only - called by df-pull after git pull
set -e

DOTFILES_DIR="$HOME/Code/rodlc/dotfiles"

# Symlink helper
symlink() {
  local source="$1" link="$2"
  [ ! -e "$source" ] && return 0
  [ -L "$link" ] && [ "$(readlink "$link")" = "$source" ] && return 0
  [ -L "$link" ] && rm "$link"
  [ ! -e "$link" ] && ln -s "$source" "$link" && echo "  → $link"
}

echo "Syncing symlinks..."

# Claude symlinks
mkdir -p "$HOME/.claude/commands" "$HOME/.claude/hooks" "$HOME/.claude/skills"
symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
symlink "$DOTFILES_DIR/claude/agent_docs" "$HOME/.claude/agent_docs"
symlink "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
symlink "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"

# Claude commands
for cmd in "$DOTFILES_DIR/claude/commands"/*.md; do
  [ -f "$cmd" ] && symlink "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
done

# Claude hooks
symlink "$DOTFILES_DIR/claude/hooks/safe-bash.sh" "$HOME/.claude/hooks/safe-bash.sh"
symlink "$DOTFILES_DIR/claude/hooks/auto-approve-skills.sh" "$HOME/.claude/hooks/auto-approve-skills.sh"

# Claude skills
for skill in terminal-title email-reply.md; do
  if [ -e "$DOTFILES_DIR/claude/skills/$skill" ]; then
    symlink "$DOTFILES_DIR/claude/skills/$skill" "$HOME/.claude/skills/$skill"
  fi
done

# Shell config
for name in aliases gitconfig irbrc pryrc rspec zprofile zshrc; do
  symlink "$DOTFILES_DIR/$name" "$HOME/.$name"
done

# SSH config
symlink "$DOTFILES_DIR/config" "$HOME/.ssh/config"

# Zed
mkdir -p "$HOME/.config/zed"
symlink "$DOTFILES_DIR/zed/settings.json" "$HOME/.config/zed/settings.json"
symlink "$DOTFILES_DIR/zed/keymap.json" "$HOME/.config/zed/keymap.json"

# Zsh modular config + Starship
mkdir -p "$HOME/.config/zsh/conf.d"
symlink "$DOTFILES_DIR/zsh/.zsh_plugins.txt" "$HOME/.config/zsh/.zsh_plugins.txt"
for conf in "$DOTFILES_DIR/zsh/conf.d"/*.zsh; do
  [ -f "$conf" ] && symlink "$conf" "$HOME/.config/zsh/conf.d/$(basename "$conf")"
done
symlink "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# Finicky
symlink "$DOTFILES_DIR/finicky.js" "$HOME/.finicky.js"
