install_dotfiles() {
  install_homebrew_packages

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
  mkdir -p "$HOME/.playwright"
  backup "$HOME/.playwright/cli.config.json"
  symlink "$DOTFILES_DIR/home/playwright/cli.config.json" "$HOME/.playwright/cli.config.json"

  # config/ → ~/.config/<app>/
  mkdir -p "$HOME/.config/pry"
  symlink "$DOTFILES_DIR/config/pry/pryrc" "$HOME/.config/pry/pryrc"
  mkdir -p "$HOME/.config/git" "$HOME/.config/mise"
  symlink "$DOTFILES_DIR/config/mise/config.toml" "$HOME/.config/mise/config.toml"
  symlink "$DOTFILES_DIR/config/git/config" "$HOME/.config/git/config"
  symlink "$DOTFILES_DIR/config/git/ignore" "$HOME/.config/git/ignore"
  mkdir -p "$HOME/.config/zsh"
  symlink "$DOTFILES_DIR/config/zsh/aliases" "$HOME/.config/zsh/aliases"

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

  echo "=====> Installing language runtimes"
  if command -v mise &>/dev/null; then
    echo "-----> Installing runtimes via mise"
    mise install
  else
    echo "⚠️  mise not found, skipping runtimes"
  fi

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
      (cd "$DOTFILES_DIR" && pre-commit install)
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

  # macOS defaults: rerun only when macos.sh changed, so a rerun does not ask again or restart Finder
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local stamp="$HOME/.local/state/dotfiles/macos.sha"
    local current=$(shasum "$DOTFILES_DIR/macos.sh" | cut -d' ' -f1)
    if [[ "$current" != "$(cat "$stamp" 2>/dev/null)" ]]; then
      zsh "$DOTFILES_DIR/macos.sh" && mkdir -p "${stamp:h}" && echo "$current" > "$stamp"
    else
      echo "✓ macOS defaults already applied (rerun: zsh macos.sh)"
    fi
  fi
}
