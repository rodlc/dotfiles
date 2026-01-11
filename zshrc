# Modular ZSH Configuration with Antidote
# Modules: ~/.config/zsh/conf.d/

# Enable true color support for Starship
export COLORTERM=truecolor

# Initialize completions (required before loading plugins)
autoload -Uz compinit && compinit

# Antidote plugin manager
source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh

# Load plugins statically (faster than dynamic)
antidote load ${ZDOTDIR:-~}/.config/zsh/.zsh_plugins.txt

# Oh-My-Zsh theme
ZSH_THEME="robbyrussell"

# Oh-My-Zsh settings
ZSH_DISABLE_COMPFIX=true
setopt NO_NOTIFY

# Remove conflicting aliases
unalias rm 2>/dev/null  # No interactive rm by default
unalias lt 2>/dev/null  # We need lt for localtunnel
unalias gm 2>/dev/null  # Override git plugin alias (custom function in .aliases)

# Starship prompt (replaces oh-my-zsh prompt)
eval "$(starship init zsh)"

# Load modular configuration
for config_file in ~/.config/zsh/conf.d/*.zsh; do
  [[ -r "$config_file" ]] && source "$config_file"
done

# Load custom aliases
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Default working directory
cd ~/Code

# Load local env if exists (optional personal config)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
