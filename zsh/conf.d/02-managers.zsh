# Ruby (rbenv)
export PATH="${HOME}/.rbenv/bin:${PATH}"
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Node (fnm - Rust, 40x faster than nvm)
if command -v fnm &> /dev/null; then
  eval "$(fnm env --use-on-cd)"
fi

# Python (pyenv) - LAZY LOAD
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
pyenv() {
  unfunction pyenv
  eval "$(command pyenv init -)"
  eval "$(command pyenv virtualenv-init - 2>/dev/null)"
  pyenv "$@"
}

# Go (goenv) - LAZY LOAD
export GOENV_ROOT="$HOME/.goenv"
[[ -d $GOENV_ROOT/bin ]] && export PATH="$GOENV_ROOT/bin:$PATH"
goenv() {
  unfunction goenv
  eval "$(command goenv init -)"
  export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
  goenv "$@"
}

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
