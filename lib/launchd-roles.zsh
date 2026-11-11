# Single-instance services run on the reference machine only; the others reach it over Tailscale
LAUNCHD_REFERENCE_ONLY=(claude-scheduler mcp-backup mcp-consolidation mcp-memory-http mcp-typology ski-watcher whatsapp-bridge)
LAUNCHD_CLIENT_ONLY=(studio-forward)
DOTFILES_ROLE_FILE="$HOME/.config/dotfiles/role"

launchd_excluded_reason() {
  local service="$1" role="$2"
  if [[ "$role" != "reference" ]] && (( ${LAUNCHD_REFERENCE_ONLY[(Ie)$service]} )); then
    echo "reference machine only"
  elif [[ "$role" == "reference" ]] && (( ${LAUNCHD_CLIENT_ONLY[(Ie)$service]} )); then
    echo "client machines only"
  fi
}
