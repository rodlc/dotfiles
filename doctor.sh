#!/bin/zsh
DOTFILES_DIR="${0:A:h}"
TIER="${1:-mcp}"  # dotfiles | workspace | mcp
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
TAILSCALE=/Applications/Tailscale.app/Contents/MacOS/Tailscale
source "$DOTFILES_DIR/lib/launchd-roles.zsh"

failures=0

check() {
  local description="$1"; shift
  if "$@" &>/dev/null; then
    echo "✓ $description"
  else
    echo "✗ $description"
    (( failures++ ))
  fi
}

no_dangling_claude_links() {
  [[ -z "$(find -L "$HOME/.claude" -maxdepth 2 -type l 2>/dev/null)" ]]
}

rayclip_installed() {
  command -v rayclip || [[ -x "$HOME/.local/bin/rayclip" ]]
}

launchd_healthy() {
  local label="$1"
  local state="$(launchctl print "gui/$UID/$label" 2>/dev/null)" || return 1
  local last_exit="$(awk -F' = ' '/^\tlast exit code/ { print $2; exit }' <<< "$state")"
  [[ -z "$last_exit" || "$last_exit" == "0" || "$last_exit" == "(never exited)" ]]
}

http_healthy() {
  curl -sf --max-time 2 "http://127.0.0.1:$1/api/health"
}

tailscale_serves() {
  "$TAILSCALE" serve status --json | jq -e --arg port "$1" '.TCP[$port]'
}

echo "=====> Doctor (tier: $TIER)"

check "Brewfile satisfied (brew bundle check)" brew bundle check --file="$DOTFILES_DIR/Brewfile" --no-upgrade
check "Brewfile.sudo satisfied (brew bundle check)" brew bundle check --file="$DOTFILES_DIR/Brewfile.sudo" --no-upgrade

if [[ "$TIER" == "workspace" || "$TIER" == "mcp" ]]; then
  check "No dangling symlinks under ~/.claude" no_dangling_claude_links
  check "rayclip installed" rayclip_installed
fi

if [[ "$TIER" == "mcp" ]]; then
  role="$(cat "$DOTFILES_ROLE_FILE" 2>/dev/null)"
  check "Machine role set (${role:-missing}, $DOTFILES_ROLE_FILE)" test -n "$role"

  whatsapp_expected=false
  for plist in "$WORKSPACE_DIR"/claude-config/launchd/*.plist(N); do
    label="${${plist:t}%.plist}"
    service="${label#com.rodlecoent.}"
    [[ -n "$(launchd_excluded_reason "$service" "$role")" ]] && continue
    [[ "$service" == "whatsapp-bridge" ]] && whatsapp_expected=true
    check "launchd $service loaded, last exit 0 or never run" launchd_healthy "$label"
  done

  ports=(4242 4243)
  $whatsapp_expected && ports+=(4244)
  for port in $ports; do
    check "HTTP 127.0.0.1:$port/api/health answers" http_healthy "$port"
  done

  if [[ "$role" == "reference" ]]; then
    for port in 4242 4243 4244; do
      check "tailscale serve forwards $port" tailscale_serves "$port"
    done
  fi
fi

(( failures == 0 )) || { echo "✗ $failures check(s) failed"; exit 1; }
echo "✓ All checks passed"
