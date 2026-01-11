# Modular ZSH Configuration
# Modules: ~/.config/zsh/conf.d/

# Oh-My-Zsh setup
ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
ZSH_DISABLE_COMPFIX=true
setopt NO_NOTIFY

# Plugins
plugins=(git gitfast last-working-dir common-aliases zsh-syntax-highlighting history-substring-search zsh-autosuggestions)

# Load Oh-My-Zsh
source "${ZSH}/oh-my-zsh.sh"

# Remove conflicting aliases
unalias rm  # No interactive rm by default
unalias lt  # We need lt for localtunnel
unalias gm  # Override git plugin alias (custom function in .aliases)

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
