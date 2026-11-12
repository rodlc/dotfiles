# Their installers prompt for the admin password, which a non-interactive run cannot answer
install_sudo_casks() {
  if brew bundle check --file="$DOTFILES_DIR/Brewfile.sudo" --no-upgrade &>/dev/null; then
    echo "✓ Sudo casks already installed"
    return
  fi
  if [ -t 0 ]; then
    echo "=====> Installing casks that need sudo"
    brew bundle --file="$DOTFILES_DIR/Brewfile.sudo" || echo "⚠️  Sudo casks failed: brew bundle --file=$DOTFILES_DIR/Brewfile.sudo"
  else
    local command="brew bundle --file=\"$DOTFILES_DIR/Brewfile.sudo\""
    cat <<EOF

╔═══════════════════════════════════════════════════════════════╗
║  ACTION NEEDED: sudo casks (veracrypt, macfuse)
║  Run in Terminal (it asks for your sudo password):
║
║    $command
║
║  The command is in your clipboard; the install keeps going
╚═══════════════════════════════════════════════════════════════╝

EOF
    print -rn -- "$command" | pbcopy || true
    osascript -e 'display notification "Sudo casks command in the clipboard: paste it in Terminal" with title "Dotfiles install"' || true
  fi
}

install_homebrew_packages() {
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
  brew bundle --file="$DOTFILES_DIR/Brewfile" || true
  local missing=$(brew bundle check --file="$DOTFILES_DIR/Brewfile" --verbose --no-upgrade 2>/dev/null | grep '^→')
  if [[ -n "$missing" ]]; then
    echo ""
    echo "⚠️  ⚠️  ⚠️  Brewfile entries still missing after brew bundle:"
    echo "$missing"
    echo ""
  fi
  install_sudo_casks

  # brew bundle skips a cask already in the Caskroom, even when another account installed its files
  brew info --cask --json=v2 --installed | jq -r '
    .casks[]
    | ([.artifacts[] | .app? // empty] | first) as $app
    | ([.artifacts[] | .font? // empty | .[0]] | first) as $font
    | if $app then "\(.token)\t/Applications/\(([$app[] | objects | .target] | first) // $app[0])"
      elif $font then "\(.token)\t\(env.HOME)/Library/Fonts/\($font | split("/") | last)"
      else empty end' |
  while IFS=$'\t' read -r cask artifact; do
    if [[ ! -e "$artifact" ]]; then
      echo "-----> Reinstalling $cask ($artifact missing)"
      brew reinstall --cask "$cask" < /dev/null || echo "⚠️  Reinstall of $cask failed"
    fi
  done
}
