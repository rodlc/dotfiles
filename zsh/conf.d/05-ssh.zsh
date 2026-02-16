# Bitwarden Desktop SSH Agent
# Falls back to macOS launchd agent if BW socket absent
local bw_sock="$HOME/.bitwarden-ssh-agent.sock"
local bw_sock_alt="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"

if [[ -S "$bw_sock" ]]; then
    export SSH_AUTH_SOCK="$bw_sock"
elif [[ -S "$bw_sock_alt" ]]; then
    export SSH_AUTH_SOCK="$bw_sock_alt"
fi
