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
    local ssh_key="$HOME/.ssh/id_ed25519_rodlc"

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
        echo "🔑 SSH key not loaded. Run: bw-pull"
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

            # CPU: instantaneous utilization (user% + sys%)
            local cpu_pct=$(top -l 2 -s 0 -FR -n 0 2>/dev/null \
                | awk '/CPU usage/ {gsub(/%/,""); printf "%.0f", $3+$5}' | tail -1)
            [[ -z "$cpu_pct" ]] && cpu_pct="0"
            output+=" | ⚡${cpu_pct}%"

            # RAM: Activity Monitor-style (app + wired + compressor)
            local ram_pct=$(vm_stat 2>/dev/null | awk \
                -v total_bytes="$(sysctl -n hw.memsize)" '
                NR==1 { ps=0; split($0, a, " "); for(i in a) if(a[i]+0>0) ps=a[i]+0 }
                /Anonymous pages:/           { gsub(/\./,"",$NF); internal=$NF }
                /Pages purgeable:/           { gsub(/\./,"",$NF); purgeable=$NF }
                /Pages wired down:/          { gsub(/\./,"",$NF); wired=$NF }
                /occupied by compressor:/    { gsub(/\./,"",$NF); compressor=$NF }
                END {
                    used = (internal - purgeable + wired + compressor) * ps
                    printf "%.0f", (used * 100) / total_bytes
                }')
            [[ -z "$ram_pct" ]] && ram_pct="0"
            output+=" | 🧠 ${ram_pct}%"

            output+=" | 💾 $(df -h ~ | tail -1 | awk '{print $5}')"

            echo "$output" > "$cache_file.tmp"
            mv -f "$cache_file.tmp" "$cache_file"
        ) &
    ) &>/dev/null

    [[ -f "$cache_file" ]] && cat "$cache_file" 2>/dev/null
}

# Only show MOTD for login shells (not subshells)
if [[ -o login ]]; then
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
      "$HOME/Code/rodlc/dotfiles/scripts/code/git-fetch-background.sh" &
    ) &>/dev/null

    check_repo_status "$HOME/Code/rodlc/dotfiles" "Dotfiles" "df-push" "df-pull"
    check_repo_status "${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}" "Workspace" "ws-push" "ws-pull"
  fi

  # Bitwarden secrets sync check
  if [[ -f "$HOME/.env" && -f "$HOME/.env.bw-synced" ]]; then
    if [[ "$HOME/.env" -nt "$HOME/.env.bw-synced" ]]; then
      echo "⚠️  Secrets modified locally. Run: bw-push"
    fi
  fi

  # Dotfiles symlink health check
  check_dotfiles_symlinks() {
    local expected="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
    for link in ~/.claude/settings.json ~/.claude/CLAUDE.md ~/.claude/statusline.sh ~/.claude/hooks/*.sh; do
      [[ ! -L "$link" ]] && continue
      local target=$(readlink "$link")
      # Broken or points to wrong user
      if [[ ! -e "$link" ]] || [[ "$target" != "$expected"* ]]; then
        echo "🌊 Drifting symlinks. Run: df-install"
        return
      fi
    done
    # Skills drift check: detect non-symlink entries
    for entry in ~/.claude/skills/*; do
      [[ ! -e "$entry" ]] && continue
      if [[ ! -L "$entry" ]]; then
        echo "🌊 Skill drift: $(basename "$entry") is not a symlink. Run: df-install"
        return
      fi
    done
  }
  check_dotfiles_symlinks

  check_cc_version() {
    command -v claude &>/dev/null || return 0
    local current=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    [[ -z "$current" ]] && return 0

    local cache_file="$HOME/.cache/cc-latest-version"
    local cache_ttl=86400  # 24h
    local latest=""

    # Read cache if fresh
    if [[ -f "$cache_file" ]]; then
      local file_time=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
      local age=$(( $(date +%s) - file_time ))
      if [[ $age -lt $cache_ttl ]]; then
        latest=$(cat "$cache_file" 2>/dev/null)
      fi
    fi

    # Refresh in background if stale/missing
    if [[ -z "$latest" ]]; then
      (
        setopt LOCAL_OPTIONS NO_MONITOR
        (
          local fetched=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
          [[ -n "$fetched" ]] && echo "$fetched" > "$cache_file.tmp" && mv -f "$cache_file.tmp" "$cache_file"
        ) &
      ) &>/dev/null
      # Use stale cache if exists
      [[ -f "$cache_file" ]] && latest=$(cat "$cache_file" 2>/dev/null)
    fi

    # Alert if outdated
    if [[ -n "$latest" && "$current" != "$latest" ]]; then
      echo "🤖 Claude Code v${current} → v${latest} (claude update)"
    fi
  }
  check_cc_version
fi
