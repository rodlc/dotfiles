#!/bin/bash
# macos.sh — macOS system preferences (idempotent)
# Run after fresh install. Requires logout/restart for some changes.
set -euo pipefail

echo "⚙️  Configuring macOS defaults..."

# ════════════════════════════════════════════
# Dock
# ════════════════════════════════════════════
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
defaults write com.apple.dock tilesize -int 67
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true

# ════════════════════════════════════════════
# Finder
# ════════════════════════════════════════════
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
# List view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# ════════════════════════════════════════════
# Keyboard
# ════════════════════════════════════════════
# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# Disable smart quotes/dashes (breaks code)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# ════════════════════════════════════════════
# Trackpad
# ════════════════════════════════════════════
# Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# Tracking speed (0-3, default ~1.5)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.5

# ════════════════════════════════════════════
# Screenshots
# ════════════════════════════════════════════
defaults write com.apple.screencapture location -string "$HOME/Desktop"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ════════════════════════════════════════════
# Misc
# ════════════════════════════════════════════
# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
# Disable "Are you sure you want to open this application?"
defaults write com.apple.LaunchServices LSQuarantine -bool false

# ════════════════════════════════════════════
# Apply
# ════════════════════════════════════════════
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "✅ macOS defaults configured (some changes require logout)"

# ════════════════════════════════════════════
# Security (interactive — prompt before each)
# ════════════════════════════════════════════
echo ""
echo "⚙️  Security hardening (each step requires confirmation)..."

read "fw_choice?Enable firewall? [y/N] "
if [[ "$fw_choice" =~ ^[Yy]$ ]]; then
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
  echo "✅ Firewall enabled"
fi

read "lock_choice?Require password on lock screen (5s delay)? [y/N] "
if [[ "$lock_choice" =~ ^[Yy]$ ]]; then
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 300
  echo "✅ Lock screen password enabled"
fi

read "airdrop_choice?Restrict AirDrop to contacts only? [y/N] "
if [[ "$airdrop_choice" =~ ^[Yy]$ ]]; then
  defaults write com.apple.sharingd DiscoverableMode -string "Contacts Only"
  echo "✅ AirDrop restricted to contacts"
fi

fv_status=$(fdesetup status 2>/dev/null || echo "unknown")
echo "FileVault: $fv_status"
if [[ "$fv_status" != *"On"* ]]; then
  read "fv_choice?Enable FileVault? [y/N] "
  if [[ "$fv_choice" =~ ^[Yy]$ ]]; then
    sudo fdesetup enable
  fi
fi

# ════════════════════════════════════════════
# Machine naming (interactive)
# ════════════════════════════════════════════
echo ""
echo "⚙️  Machine naming..."
echo "Current: $(scutil --get ComputerName 2>/dev/null || echo 'not set')"

read "name_choice?Set machine name? [y/N] "
if [[ "$name_choice" =~ ^[Yy]$ ]]; then
  read "computer_name?ComputerName (e.g. Rod MacBook Pro): "
  read "local_host?LocalHostName (e.g. rod-macbook-pro): "
  if [[ -n "$computer_name" && -n "$local_host" ]]; then
    sudo scutil --set ComputerName "$computer_name"
    sudo scutil --set LocalHostName "$local_host"
    sudo scutil --set HostName "$local_host"
    echo "✅ Machine named: $computer_name ($local_host)"
  fi
fi
