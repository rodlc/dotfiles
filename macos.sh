#!/bin/zsh
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
echo "⚙️  Security hardening (asks only when a setting differs)..."

if [[ "$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)" == *enabled* ]]; then
  echo "✓ Firewall on"
else
  read "fw_choice?Enable firewall? [y/N] "
  if [[ "$fw_choice" =~ ^[Yy]$ ]]; then
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    echo "✅ Firewall enabled"
  fi
fi

# com.apple.screensaver askForPassword is ignored since macOS 10.13, sysadminctl is the supported path
if [[ "$(sysadminctl -screenLock status 2>&1)" == *"delay is 5 seconds"* ]]; then
  echo "✓ Lock screen password after 5s"
else
  read "lock_choice?Require password on lock screen (5s delay)? [y/N] "
  if [[ "$lock_choice" =~ ^[Yy]$ ]]; then
    sysadminctl -screenLock 5 -password -
    echo "✅ Lock screen password enabled"
  fi
fi

if [[ "$(defaults read com.apple.sharingd DiscoverableMode 2>/dev/null)" == "Contacts Only" ]]; then
  echo "✓ AirDrop contacts only"
else
  read "airdrop_choice?Restrict AirDrop to contacts only? [y/N] "
  if [[ "$airdrop_choice" =~ ^[Yy]$ ]]; then
    defaults write com.apple.sharingd DiscoverableMode -string "Contacts Only"
    echo "✅ AirDrop restricted to contacts"
  fi
fi

fv_status=$(fdesetup status 2>/dev/null || echo "unknown")
if [[ "$fv_status" == *"On"* ]]; then
  echo "✓ FileVault on"
else
  read "fv_choice?Enable FileVault? [y/N] "
  if [[ "$fv_choice" =~ ^[Yy]$ ]]; then
    sudo fdesetup enable
    echo "⚠️  Store the recovery key in Bitwarden, never paste it elsewhere"
  fi
fi

# ════════════════════════════════════════════
# Machine naming (interactive)
# ════════════════════════════════════════════
# Convention: ComputerName "Rod <Model>", LocalHostName = HostName "rod-<model>"
echo ""
computer_name=$(scutil --get ComputerName 2>/dev/null || echo "")
local_host=$(scutil --get LocalHostName 2>/dev/null || echo "")
host_name=$(scutil --get HostName 2>/dev/null || echo "")
if [[ "$computer_name" == "Rod "* && "$local_host" == rod-* && "$host_name" == "$local_host" ]]; then
  echo "✓ Machine named: $computer_name ($local_host)"
else
  echo "Current: ${computer_name:-not set} (${local_host:-not set})"
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
fi
