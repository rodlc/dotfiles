ZSH=$HOME/.oh-my-zsh

# You can change the theme with another one from https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="robbyrussell"

# Useful oh-my-zsh plugins for Le Wagon bootcamps
plugins=(git gitfast last-working-dir common-aliases zsh-syntax-highlighting history-substring-search zsh-autosuggestions)

# (macOS-only) Prevent Homebrew from reporting - https://github.com/Homebrew/brew/blob/master/docs/Analytics.md
export HOMEBREW_NO_ANALYTICS=1

# Disable warning about insecure completion-dependent directories
ZSH_DISABLE_COMPFIX=true

# Actually load Oh-My-Zsh
source "${ZSH}/oh-my-zsh.sh"
unalias rm # No interactive rm by default (brought by plugins/common-aliases)
unalias lt # we need `lt` for https://github.com/localtunnel/localtunnel
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

# Load pyenv (to manage your Python versions) - AFTER Homebrew to override python3
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
type -a pyenv > /dev/null && eval "$(pyenv init -)" && eval "$(pyenv virtualenv-init - 2> /dev/null)" && RPROMPT='[🐍 $(pyenv version-name)]'

# MCP Notion timeout configuration (fix timeouts)
export MCP_TIMEOUT=30000

# Secrets (Bitwarden → ~/.env). Sync: bw-sync-env. Never commit ~/.env
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

# Dotfiles & Claude context sync check (MOTD)
if [ -d "$HOME/Code/rodlc/dotfiles/.git" ]; then
  (
    cd "$HOME/Code/rodlc/dotfiles" 2>/dev/null
    git fetch origin main >/dev/null 2>&1 &

    [ -n "$(git status --porcelain 2>/dev/null)" ] && echo "⚠️  Dotfiles have uncommitted changes. Run: df-push"

    local behind=$(git rev-list HEAD...origin/main --count 2>/dev/null)
    [ "$behind" != "0" ] && [ -n "$behind" ] && echo "🔄 Dotfiles outdated ($behind commits). Run: df-pull"
  ) 2>/dev/null
fi

if [ -d "$HOME/Code/rodlc/claude-context/.git" ]; then
  (
    cd "$HOME/Code/rodlc/claude-context" 2>/dev/null
    git fetch origin main >/dev/null 2>&1 &

    [ -n "$(git status --porcelain 2>/dev/null)" ] && echo "⚠️  Claude context has uncommitted changes. Run: context-sync"

    local behind=$(git rev-list HEAD...origin/main --count 2>/dev/null)
    [ "$behind" != "0" ] && [ -n "$behind" ] && echo "🔄 Claude context outdated ($behind commits). Run: context-sync pull"
  ) 2>/dev/null
fi

. "$HOME/.local/bin/env"
