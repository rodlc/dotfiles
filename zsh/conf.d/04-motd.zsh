# MOTD - SSH-aware Git Status with Background Fetch

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
        echo "🔑 SSH key loaded. Fetching git status..."
        return 0
    fi

    # Agent empty - check if key exists
    if [[ ! -f "$ssh_key" ]]; then
        echo "🔑 SSH key missing. Run: bw-pull"
        return 2
    else
        echo "🔑 SSH key not loaded. Run: ssh-add"
        return 1
    fi
}

check_repo_status() {
    local repo_path="$1"
    local repo_name="$2"
    local alias_push="$3"
    local alias_pull="$4"

    [[ ! -d "$repo_path/.git" ]] && return 0

    local cache_dir="$HOME/.cache"
    mkdir -p "$cache_dir"
    local cache_file="$cache_dir/git-status-$repo_name"

    if [[ -f "$cache_file" ]]; then
        local current_time=$(date +%s)
        local file_time=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
        local age=$((current_time - file_time))
        local age_display=$(format_cache_age $age)

        local content=$(cat "$cache_file" 2>/dev/null)
        if [[ -n "$content" ]]; then
            echo "$content" | while IFS= read -r line; do
                [[ -n "$line" ]] && echo "$line [$age_display]"
            done
        fi
    fi
}

# System info compact (cached 5min)
show_system_info() {
    local cache_dir="$HOME/.cache"
    mkdir -p "$cache_dir"
    local cache_file="$cache_dir/zsh-system-info"
    local cache_ttl=300

    local cache_age=999999
    if [[ -f "$cache_file" ]]; then
        local current_time=$(date +%s)
        local file_time=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
        cache_age=$((current_time - file_time))
    fi

    if [[ $cache_age -lt $cache_ttl ]]; then
        cat "$cache_file" 2>/dev/null
        return 0
    fi

    # Refresh cache in background
    (
        setopt LOCAL_OPTIONS NO_MONITOR
        (
            local output=""
            local boot=$(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')
            local up=$(($(date +%s) - boot))
            local d=$((up/86400)) h=$(((up%86400)/3600)) m=$(((up%3600)/60))
            local uptime_compact="${d}d ${h}h ${m}m"
            [[ $d -eq 0 ]] && uptime_compact="${h}h ${m}m"
            [[ $d -eq 0 && $h -eq 0 ]] && uptime_compact="${m}m"
            output+="⏱️  ${uptime_compact}"

            local load=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
            local cores=$(sysctl -n hw.ncpu 2>/dev/null)
            local cpu_pct=$(awk -v l="$load" -v c="$cores" 'BEGIN {printf "%.0f", (l/c)*100}')
            output+=" | ⚡${cpu_pct}%"

            local total_ram=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024/1024}')
            output+=" | 🧠 $(top -l 1 | grep PhysMem | awk -v total="$total_ram" '{used=$2; gsub(/G/, "", used); printf "%.0f%%", (used/total)*100}')"

            output+=" | 💾 $(df -h ~ | tail -1 | awk '{print $5}')"

            echo "$output" > "$cache_file.tmp"
            mv -f "$cache_file.tmp" "$cache_file"
        ) &
    ) &>/dev/null

    [[ -f "$cache_file" ]] && cat "$cache_file" 2>/dev/null
}

# Display greeting and system info
echo "Hello, world!"
show_system_info

# Run SSH check first
ssh_status_code=0
check_ssh_status
ssh_status_code=$?

# Only run git checks if SSH is OK
if [[ $ssh_status_code -eq 0 ]]; then
    (
        setopt LOCAL_OPTIONS NO_MONITOR
        "$HOME/Code/rodlc/dotfiles/scripts/git-fetch-background.sh" &
    ) &>/dev/null

    check_repo_status "$HOME/Code/rodlc/dotfiles" "Dotfiles" "df-push" "df-pull"
    check_repo_status "$HOME/Code/rodlc/workspace" "Workspace" "workspace-push" "workspace-pull"
fi

# Bitwarden secrets sync check
if [[ -f "$HOME/.env" && -f "$HOME/.env.bw-synced" ]]; then
    if [[ "$HOME/.env" -nt "$HOME/.env.bw-synced" ]]; then
        echo "⚠️  Secrets modified locally. Run: bw-push"
    fi
fi
