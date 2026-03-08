# Persist last working directory across terminal sessions
autoload -U add-zsh-hook

typeset -g __LAST_DIR_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/last-dir"

# Save CWD on every directory change (skip subshells)
chpwd_last_working_dir() {
  [[ "$ZSH_SUBSHELL" -eq 0 ]] || return 0
  print -r -- "$PWD" >| "$__LAST_DIR_FILE"
}
add-zsh-hook chpwd chpwd_last_working_dir

# Restore on shell startup (interactive only)
if [[ -r "$__LAST_DIR_FILE" ]]; then
  local _last_dir
  _last_dir=$(<"$__LAST_DIR_FILE")
  [[ -d "$_last_dir" ]] && cd "$_last_dir" || cd ~/Code
else
  cd ~/Code
fi
