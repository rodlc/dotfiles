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
        echo "🔑 SSH key loaded, fetching git..."
        return 0
    fi

    # Agent empty - check if key exists
    if [[ ! -f "$ssh_key" ]]; then
        echo "🔑 SSH key missing ⇒ bw-pull"
        return 2
    else
        echo "🔑 SSH key not loaded ⇒ bw-pull"
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
            local last_line=$(echo "$content" | tail -1)
            echo "$content" | while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    [[ "$line" == "$last_line" ]] && echo "$line [$age_display]" || echo "$line"
                fi
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
  printf '\033[0m'
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
  if [[ ! -f "$HOME/.env" ]]; then
    echo "🔐 ~/.env missing ⇒ bw-pull"
  elif [[ ! -f "$HOME/.env.bw-synced" ]]; then
    echo "🔐 Secrets never synced ⇒ bw-push"
  elif [[ "$HOME/.env" -nt "$HOME/.env.bw-synced" ]]; then
    echo "🔐 Secrets modified locally ⇒ bw-push"
  fi

  check_drift() {
    setopt LOCAL_OPTIONS NULL_GLOB
    local ws="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"
    local cc="$ws/claude-config"
    local -a labels fixes
    local fatal=0

    # Fatal: symlink health
    for link in ~/.claude/settings.json ~/.claude/CLAUDE.md ~/.claude/statusline.sh ~/.claude/hooks/*.sh ~/.claude/hooks/core; do
      [[ ! -L "$link" ]] && continue
      local target=$(readlink "$link")
      if [[ ! -e "$link" ]] || [[ "$target" != "$ws"* ]]; then
        labels+=("drifting symlinks"); fixes+=("df-install workspace"); fatal=1; break
      fi
    done

    # Fatal: skills drift
    if (( ! fatal )); then
      for entry in ~/.claude/skills/*; do
        [[ ! -e "$entry" ]] && continue
        if [[ ! -L "$entry" ]]; then
          labels+=("skill not symlinked"); fixes+=("df-install workspace"); fatal=1; break
        fi
      done
    fi

    # Fatal: orphan detection
    if (( ! fatal )); then
      for entry in ~/.claude/rules/* ~/.claude/commands/* ~/.claude/agent_docs/* ~/.claude/hooks/*.sh ~/.claude/hooks/*.js ~/.claude/hooks/*.json ~/.claude/hooks/core/* ~/.claude/hooks/utilities/*; do
        [[ ! -e "$entry" ]] && continue
        [[ -L "$(dirname "$entry")" ]] && continue
        if [[ ! -L "$entry" ]]; then
          labels+=("orphan detected"); fixes+=("df-install workspace"); fatal=1; break
        fi
      done
    fi

    if (( ! fatal )); then
      [[ -f "$ws/.claude/settings.json" ]] && labels+=("settings.json scope drift") && fixes+=("rm $ws/.claude/settings.json")
      local wt_drift=$(find "$ws/.claude/worktrees" -path "*/.claude/settings.json" 2>/dev/null | head -1)
      [[ -n "$wt_drift" ]] && labels+=("worktree settings.json") && fixes+=("rm $wt_drift")

      local lock_sym="$ws/skills-lock.json"
      if [[ -L "$lock_sym" ]]; then
        local target=$(readlink "$lock_sym")
        [[ "$target" != *claude-config/skills-lock.json ]] && [[ "$target" != claude-config/skills-lock.json ]] && \
          labels+=("skills-lock bad target") && fixes+=("df-install workspace")
      elif [[ -e "$lock_sym" ]]; then
        labels+=("skills-lock not symlinked") && fixes+=("df-install workspace")
      else
        labels+=("skills-lock missing") && fixes+=("df-install workspace")
      fi

      if [[ -d "$cc" ]]; then
        local dirty=$(git -C "$ws" diff --name-only -- claude-config/ 2>/dev/null | head -1)
        local staged=$(git -C "$ws" diff --cached --name-only -- claude-config/ 2>/dev/null | head -1)
        [[ -n "$dirty" || -n "$staged" ]] && labels+=("uncommitted") && fixes+=("ws-push")
      fi

      local template="$ws/.claude/mcp-template.json"
      local live="$HOME/.claude.json"
      if [[ -f "$template" && -f "$live" ]]; then
        local count=$(
          set -a; source "$HOME/.env" 2>/dev/null || { echo 0; return; }; set +a
          local expanded=$(envsubst < "$template" 2>/dev/null | jq -S '.mcpServers' 2>/dev/null) || { echo 0; return; }
          local current=$(jq -S '.mcpServers' "$live" 2>/dev/null) || { echo 0; return; }
          [[ -z "$expanded" || -z "$current" ]] && { echo 0; return; }
          diff <(echo "$expanded") <(echo "$current") 2>/dev/null | grep -c '^[<>]' || echo 0
        )
        [[ "$count" =~ ^[0-9]+$ && "$count" -gt 0 ]] && labels+=("MCP stale (${count}Δ)") && fixes+=("mcp-sync.sh diff")
      fi
    fi

    if (( ${#labels} )); then
      local -aU uf=("${fixes[@]}")
      echo "🌊 claude-config ${(j:, :)labels} ⇒ ${(j:, :)uf}"
    fi
  }
  check_drift

  check_backup_freshness() {
    setopt LOCAL_OPTIONS NULL_GLOB
    local backup_dir="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Backup/MCP_Memory"
    local now=$(date +%s)
    local max_age=$((48 * 3600))
    local -a parts

    for name in sqlite_vec typology plan-cache; do
      local -a files=("$backup_dir/$name"/${name}-*.db(Nom))
      if [[ ${#files} -eq 0 ]]; then
        parts+=("${name}.db missing")
        continue
      fi
      local mtime=$(stat -f %m "${files[1]}" 2>/dev/null || echo 0)
      local age=$((now - mtime))
      (( age > max_age )) && parts+=("${name}.db $((age / 3600))h")
    done

    (( ${#parts} )) && echo "📦  Backup stale ${(j:, :)parts} ⇒ mcp-backup"
  }
  check_backup_freshness

  check_scheduled_agents() {
    local cache_file="$HOME/.cache/claude-jobs"
    [[ ! -f "$cache_file" ]] && return 0

    local planned=$(jq -r '.planned // 0' "$cache_file" 2>/dev/null)
    local running=$(jq -r '.running // 0' "$cache_file" 2>/dev/null)
    local failed=$(jq -r '.failed // 0' "$cache_file" 2>/dev/null)
    local succeeded=$(jq -r '.succeeded // 0' "$cache_file" 2>/dev/null)
    [[ -z "$planned" ]] && planned=0
    [[ -z "$running" ]] && running=0
    [[ -z "$failed" ]] && failed=0
    [[ -z "$succeeded" ]] && succeeded=0

    (( planned == 0 && running == 0 && failed == 0 && succeeded == 0 )) && return 0

    local file_time=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
    local age=$(( $(date +%s) - file_time ))

    local -a parts
    (( failed > 0 ))    && parts+=("${failed} failed")
    (( running > 0 ))   && parts+=("${running} running")
    (( succeeded > 0 )) && parts+=("${succeeded} succeeded")
    (( planned > 0 ))   && parts+=("${planned} planned")

    echo "🦾 Claude Jobs ${(j:, :)parts} ⇒ claude-jobs [$(format_cache_age $age)]"
  }
  check_scheduled_agents

  check_cc_version() {
    local claude_bin=$(command -v claude 2>/dev/null)
    [[ -z "$claude_bin" ]] && return 0
    local current=$("$claude_bin" --version 2>/dev/null | awk '{print $1}')

    # CVE-2025-54794 — minimum patched version
    local min_version="2.1.90"
    if [[ -n "$current" ]]; then
      local sorted_first=$(printf '%s\n%s\n' "$min_version" "$current" | sort -V | head -1)
      if [[ "$sorted_first" != "$min_version" ]]; then
        echo "🛡️ Claude Code v${current} < v${min_version} (CVE-2025-54794) ⇒ claude update"
      fi
    fi

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

    # Alert only if latest > current (ignore stale cache where current > latest)
    if [[ -n "$latest" && "$current" != "$latest" ]]; then
      local sorted_min=$(printf '%s\n%s\n' "$current" "$latest" | sort -V | head -1)
      if [[ "$sorted_min" == "$current" ]]; then
        local update_cmd="claude update"
        [[ "$claude_bin" == *"/mise/"* ]] && update_cmd="mise upgrade claude-code"
        local age_display=""
        [[ -n "$age" && $age -lt $cache_ttl ]] && age_display=" [$(format_cache_age $age)]"
        echo "🤖 Claude Code v${current} → v${latest} ⇒ ${update_cmd}${age_display}"
      fi
    fi
  }
  check_cc_version

fi
