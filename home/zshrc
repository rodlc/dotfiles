# Modular ZSH Configuration with Antidote
# Modules: ~/.config/zsh/conf.d/

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Zsh history (XDG-compliant)
export HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "$XDG_STATE_HOME/zsh" 2>/dev/null

# Claude Code temp directory (scoped, does not affect system TMPDIR)
export CLAUDE_CODE_TMPDIR="$HOME/.claude/tmp"
mkdir -p "$CLAUDE_CODE_TMPDIR" 2>/dev/null

# Initialize completions with daily cache optimization
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-~}/.zcompdump(#qN.mh+24) ]]; then
  compinit -i  # Rebuild cache once per day
else
  compinit -i -C  # Use existing cache
fi

# Antidote plugin manager
source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh

# Load plugins statically (faster than dynamic)
antidote load ${ZDOTDIR:-~}/.config/zsh/.zsh_plugins.txt

setopt NO_NOTIFY

# Remove conflicting aliases
unalias rm 2>/dev/null  # No interactive rm by default
unalias lt 2>/dev/null  # We need lt for localtunnel
unalias gm 2>/dev/null  # Override git plugin alias (custom function in aliases)

# Starship prompt (replaces oh-my-zsh prompt)
eval "$(starship init zsh)"

# direnv hook
eval "$(direnv hook zsh)"

# Load modular configuration
for config_file in ~/.config/zsh/conf.d/*.zsh; do
  [[ -r "$config_file" ]] && source "$config_file"
done

# Load custom aliases
[[ -f "$HOME/.config/zsh/aliases" ]] && source "$HOME/.config/zsh/aliases"

# Default working directory
cd ~/Code

# Load local env if exists (optional personal config)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
