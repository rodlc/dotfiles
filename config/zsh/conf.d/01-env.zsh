# Environment variables
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Editor
export BUNDLER_EDITOR="zed --wait"
export EDITOR="zed --wait"
export VISUAL="zed --wait"

# Python
export PYTHONBREAKPOINT=ipdb.set_trace

# SSL certificates (Homebrew)
export SSL_CERT_FILE=/opt/homebrew/etc/openssl@3/cert.pem
export SSL_CERT_DIR=/opt/homebrew/etc/openssl@3/certs

# PATH configuration
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="./bin:./node_modules/.bin:${PATH}:/usr/local/sbin"

# Secrets (Bitwarden → ~/.env). Sync: bw-pull. Never commit ~/.env
if [[ -f "$HOME/.env" ]]; then
  set -a
  source "$HOME/.env"
  set +a
fi

# Disable Homebrew analytics
export HOMEBREW_NO_ANALYTICS=1

# Workspace path (fallback if not set via ~/.env by install.sh workspace)
export WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/Code/rodlc/workspace}"

# Claude Code — 1M context on Max plan (bypasses client-side s1mAccessCache bug)
export ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-6[1m]'
