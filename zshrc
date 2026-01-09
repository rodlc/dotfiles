ZSH=$HOME/.oh-my-zsh

# You can change the theme with another one from https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="robbyrussell"

# Custom prompt: username (+ hostname if SSH) + robbyrussell style
local ret_status="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
PROMPT='%{$fg[cyan]%}%n${SSH_CONNECTION:+"@%m"}%{$reset_color%} ${ret_status}%{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'

# Useful Oh-My-Zsh plugins for Le Wagon bootcamps
plugins=(git gitfast last-working-dir common-aliases zsh-syntax-highlighting history-substring-search zsh-autosuggestions)

# (macOS-only) Prevent Homebrew from reporting - https://github.com/Homebrew/brew/blob/master/docs/Analytics.md
export HOMEBREW_NO_ANALYTICS=1

# Disable warning about insecure completion-dependent directories
ZSH_DISABLE_COMPFIX=true

# Disable background job notifications
setopt NO_NOTIFY

# Actually load Oh-My-Zsh
source "${ZSH}/oh-my-zsh.sh"
unalias rm # No interactive rm by default (brought by plugins/common-aliases)
unalias lt # We need `lt` for https://github.com/localtunnel/localtunnel
unalias gm # Override git plugin alias (custom function in .aliases)

# Load rbenv if installed (to manage your Ruby versions)
export PATH="${HOME}/.rbenv/bin:${PATH}" # Needed for Linux/WSL
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Load nvm (to manage your node versions)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Call `nvm use` automatically in a directory with a `.nvmrc` file
autoload -U add-zsh-hook
load-nvmrc() {
  if nvm -v &> /dev/null; then
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use --silent
      fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
      nvm use default --silent
    fi
  fi
}
type -a nvm > /dev/null && add-zsh-hook chpwd load-nvmrc
type -a nvm > /dev/null && load-nvmrc

# Rails and Ruby uses the local `bin` folder to store binstubs.
# So instead of running `bin/rails` like the doc says, just run `rails`
# Same for `./node_modules/.bin` and nodejs
export PATH="./bin:./node_modules/.bin:${PATH}:/usr/local/sbin"

# Store your own aliases in the ~/.aliases file and load the here.
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Encoding stuff for the terminal
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Default editor
export BUNDLER_EDITOR="zed --wait"
export EDITOR="zed --wait"
export VISUAL="zed --wait"

# Set ipdb as the default Python debugger
export PYTHONBREAKPOINT=ipdb.set_trace
export SSL_CERT_FILE=/opt/homebrew/etc/openssl@3/cert.pem
export SSL_CERT_DIR=/opt/homebrew/etc/openssl@3/certs
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Load pyenv (to manage your Python versions) - after Homebrew to override python3
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
type -a pyenv > /dev/null && eval "$(pyenv init -)" && eval "$(pyenv virtualenv-init - 2> /dev/null)"

# MCP Notion timeout configuration (fix timeouts)
export MCP_TIMEOUT=30000

# Secrets (Bitwarden → ~/.env). Sync: bw-pull. Never commit ~/.env
[[ -f "$HOME/.env" ]] && source "$HOME/.env"

# Default working directory
cd ~/Code

# Claude terminal title configuration
export CLAUDE_TITLE_PREFIX="🤖"
update_terminal_cwd() {
    local title_file="${HOME}/.claude/terminal_title"

    if [ -f "$title_file" ]; then
        local claude_title=$(cat "$title_file" 2>/dev/null)

        if [ -n "$claude_title" ]; then
            if [ -n "$CLAUDE_TITLE_CLAIMED" ]; then
                printf '\033]0;%s\007' "$claude_title"
                return
            else
                local current_time=$(date +%s)
                local file_time

                if [[ "$OSTYPE" == "darwin"* ]]; then
                    file_time=$(stat -f %m "$title_file" 2>/dev/null)
                else
                    file_time=$(stat -c %Y "$title_file" 2>/dev/null)
                fi

                if [[ -z "$file_time" ]] || ! [[ "$file_time" =~ ^[0-9]+$ ]]; then
                    printf '\033]0;%s\007' "${PWD/#$HOME/~}"
                    return
                fi

                local age=$((current_time - file_time))

                if [ $age -lt 300 ]; then
                    export CLAUDE_TITLE_CLAIMED=1
                    printf '\033]0;%s\007' "$claude_title"
                    return
                fi
            fi
        fi
    fi

    printf '\033]0;%s\007' "${PWD/#$HOME/~}"
}

if [[ ! "${precmd_functions[(r)update_terminal_cwd]}" == "update_terminal_cwd" ]]; then
    precmd_functions+=(update_terminal_cwd)
fi

# MCP Memory - Dream consolidation configuration
export MCP_CONSOLIDATION_ENABLED=true

# Quality scoring with implicit signals (access_count, recency, ranking)
export MCP_QUALITY_BOOST_ENABLED=true
export MCP_QUALITY_BOOST_WEIGHT=0.3  # 30% implicit signals, 70% semantic

# Association-based quality boost (v8.47.0+)
export MCP_CONSOLIDATION_QUALITY_BOOST_ENABLED=true
export MCP_CONSOLIDATION_MIN_CONNECTIONS_FOR_BOOST=3
export MCP_CONSOLIDATION_QUALITY_BOOST_FACTOR=1.2

# Graph storage for associations persistence
export GRAPH_STORAGE_MODE=dual_write

# Consolidation scheduling (APScheduler)
export MCP_CONSOLIDATION_SCHEDULE_DAILY="14:00"
export MCP_CONSOLIDATION_SCHEDULE_WEEKLY="SUN 14:00"
export MCP_CONSOLIDATION_SCHEDULE_MONTHLY="01 14:00"
export MCP_CONSOLIDATION_SCHEDULE_QUARTERLY="disabled"
export MCP_CONSOLIDATION_SCHEDULE_YEARLY="disabled"

# Enabled phases per horizon (skip clustering/archiving for small corpus)
export MCP_CONSOLIDATION_ENABLED_PHASES_ASSOCIATIONS="weekly,monthly"
export MCP_CONSOLIDATION_ENABLED_PHASES_COMPRESSION="weekly,monthly"
export MCP_CONSOLIDATION_ENABLED_PHASES_CLUSTERING="disabled"
export MCP_CONSOLIDATION_ENABLED_PHASES_FORGETTING="disabled"

# Retention periods by memory type (days)
export MCP_CONSOLIDATION_RETENTION_CRITICAL=365    # T1 equivalent
export MCP_CONSOLIDATION_RETENTION_REFERENCE=180   # T2 equivalent
export MCP_CONSOLIDATION_RETENTION_STANDARD=90     # T3 equivalent
export MCP_CONSOLIDATION_RETENTION_TEMPORARY=30    # T4 equivalent

# ============================================================================
# MOTD - SSH-aware Git Status with Background Fetch
# ============================================================================

# Format cache age for display
format_cache_age() {
    local age_seconds=$1
    if [[ $age_seconds -lt 60 ]]; then
        echo "${age_seconds}s"
    elif [[ $age_seconds -lt 3600 ]]; then
        echo "$((age_seconds / 60))m"
    else
        echo "$((age_seconds / 3600))h"
    fi
}

# Check SSH agent status
check_ssh_status() {
    local ssh_key="$HOME/.ssh/id_ed25519"

    # Check if SSH agent has keys loaded
    if ssh-add -l &>/dev/null; then
        return 0  # SSH OK - background fetch will run
    fi

    # Agent empty - check if key exists
    if [[ ! -f "$ssh_key" ]]; then
        echo "🔑 SSH key missing. Run: bw-pull"
        return 2  # Key missing
    else
        echo "🔑 SSH key not loaded. Run: ssh-add"
        return 1  # Key exists but not loaded
    fi
}

check_repo_status() {
    local repo_path="$1"
    local repo_name="$2"
    local alias_push="$3"
    local alias_pull="$4"

    # Check if repo exists
    [[ ! -d "$repo_path/.git" ]] && return 0

    # Cache setup
    local cache_dir="$HOME/.cache"
    mkdir -p "$cache_dir"
    local cache_file="$cache_dir/git-status-$repo_name"

    # Read and display cache with age
    if [[ -f "$cache_file" ]]; then
        local content=$(cat "$cache_file" 2>/dev/null)
        if [[ -n "$content" ]]; then
            local current_time=$(date +%s)
            local file_time=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
            local age=$((current_time - file_time))
            local age_display=$(format_cache_age $age)

            # Display each line with age suffix
            echo "$content" | while IFS= read -r line; do
                [[ -n "$line" ]] && echo "$line  [$age_display]"
            done
        fi
    fi
}

# Run SSH check first
ssh_status_code=0
check_ssh_status
ssh_status_code=$?

# Only run git checks if SSH is OK
if [[ $ssh_status_code -eq 0 ]]; then
    # Launch background fetch job (subshell to hide job notification)
    ( "$HOME/Code/rodlc/dotfiles/scripts/git-fetch-background.sh" &>/dev/null & )

    # Display git status from cache
    check_repo_status "$HOME/Code/rodlc/dotfiles" "Dotfiles" "df-push" "df-pull"
    check_repo_status "$HOME/Code/rodlc/workspace" "Workspace" "workspace-push" "workspace-pull"
fi

# System info compact (cached 5min)
show_system_info() {
    local cache_dir="$HOME/.cache"
    mkdir -p "$cache_dir"
    local cache_file="$cache_dir/zsh-system-info"
    local cache_ttl=300  # 5 minutes

    # Check cache age
    local cache_age=999999
    if [[ -f "$cache_file" ]]; then
        local current_time=$(date +%s)
        local file_time=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
        cache_age=$((current_time - file_time))
    fi

    # Use cache if fresh
    if [[ $cache_age -lt $cache_ttl ]]; then
        cat "$cache_file" 2>/dev/null
        return 0
    fi

    # Refresh cache in background
    (
        local output=""
        output+="⏱️  $(uptime | sed 's/.*up //' | sed 's/, [0-9]* user.*//' | xargs)"

        # CPU load percentage
        local load=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
        local cores=$(sysctl -n hw.ncpu 2>/dev/null)
        local cpu_pct=$(awk -v l="$load" -v c="$cores" 'BEGIN {printf "%.0f", (l/c)*100}')
        output+=" | ⚡ ${cpu_pct}%"

        # RAM usage
        output+=" | 🧠 $(top -l 1 | grep PhysMem | awk '{used=$2; total=16; gsub(/G/, "", used); printf "%.0f%%", (used/total)*100}')"

        # Disk usage
        output+=" | 💾 $(df -h ~ | tail -1 | awk '{print $5}')"

        # Language versions
        command -v ruby &>/dev/null && output+=" | 💎 $(ruby --version 2>/dev/null | awk '{print $2}')"
        command -v node &>/dev/null && output+=" | 📦 $(node --version 2>/dev/null)"
        command -v python3 &>/dev/null && output+=" | 🐍 $(python3 --version 2>/dev/null | awk '{print $2}')"

        echo "$output" > "$cache_file.tmp"
        mv -f "$cache_file.tmp" "$cache_file"
    ) &>/dev/null &

    # Display cached version
    [[ -f "$cache_file" ]] && cat "$cache_file" 2>/dev/null
}
show_system_info

# Bitwarden secrets sync check
if [[ -f "$HOME/.env" && -f "$HOME/.env.bw-synced" ]]; then
    if [[ "$HOME/.env" -nt "$HOME/.env.bw-synced" ]]; then
        echo "⚠️  Secrets modified locally. Run: bw-push"
    fi
fi

# Load local env if exists (optional personal config)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# bun completions
[ -s "/Users/rodlecoent/.bun/_bun" ] && source "/Users/rodlecoent/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
