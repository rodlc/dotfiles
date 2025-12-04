# Dotfiles

Personal development environment configuration. Fork of [Le Wagon dotfiles](https://github.com/lewagon/dotfiles) with custom setup for macOS.

## Start

```bash
cd ~/Code
git clone git@github.com:rodlc/dotfiles.git
cd dotfiles
./install.sh
```

The script will automatically:
1. **Install tools** (Homebrew, Zed, Claude Code, pyenv, rbenv, nvm, oh-my-zsh)
2. **Backup** existing config files as `*.backup`
3. **Create symlinks** from `~/.config` to this repo
4. **Install plugins** (zsh-autosuggestions, zsh-syntax-highlighting)

After installation, restart your terminal or run `source ~/.zshrc`.

## Structure

```
dotfiles/
├── install.sh              # Installation script (idempotent)
├── aliases                 # Shell aliases
├── zshrc                   # Zsh configuration
├── zprofile                # Zsh profile (PATH setup)
├── gitconfig               # Git configuration
├── irbrc                   # Ruby IRB config
├── pryrc                   # Pry config
├── rspec                   # RSpec config
├── config                  # SSH config
├── zed/
│   ├── settings.json       # Zed editor settings
│   └── keymap.json         # Zed keybindings
└── claude/
    ├── CLAUDE.md           # Claude Code global instructions
    └── commands/
        └── notion.md       # /notion slash command
```

## Security

- **Secrets**: API keys and tokens are stored in `~/.env` (not versioned)
- **Pre-commit hooks**: [Gitleaks](https://github.com/gitleaks/gitleaks) scans for secrets before each commit
- **SSH keys**: `config` file references keys, but keys themselves stay in `~/.ssh/`

### Setup Pre-commit Hooks

After cloning the repo:
```bash
cd ~/Code/rodlc/dotfiles
pre-commit install  # Installs git hook
```

The hook runs automatically on `git commit`. To skip temporarily: `SKIP=gitleaks git commit -m "message"`

See [dotfiles security best practices](https://medium.com/@instatunnel/why-your-public-dotfiles-are-a-security-minefield-fc9bdff62403) and [Gitleaks pre-commit guide](https://medium.com/@ibm_ptc_security/securing-your-repositories-with-gitleaks-and-pre-commit-27691eca478d).

## Notion Integration

Claude Code connects to Notion for task management. Configuration in `claude/CLAUDE.md` includes:
- Tasks database ID
- Projects database ID
- Areas database ID

Use `/notion` command in Claude Code to save session summaries.

## Customization

Fork this repo and edit configs:
- `zshrc`: Add personal aliases and PATH modifications
- `zed/settings.json`: Adjust editor theme, fonts, keybindings
- `claude/CLAUDE.md`: Update Notion IDs and coding preferences
- `~/.env`: Store secrets (ANTHROPIC_API_KEY, GITHUB_TOKEN, etc.)

## Testing

On a fresh machine or after major changes:
```bash
cd ~/Code/rodlc/dotfiles
./install.sh
```

The script is **idempotent** - safe to run multiple times without duplicating work.

Check symlinks: `ls -la ~/.zshrc ~/.config/zed/settings.json ~/.claude/CLAUDE.md`

## References

- [Zed via Homebrew](https://formulae.brew.sh/cask/zed)
- [Claude Code native installer](https://docs.anthropic.com/en/docs/claude-code/troubleshooting)
- [oh-my-zsh installation](https://ohmyz.sh/)
- [pyenv on macOS](https://github.com/pyenv/pyenv)
- [Thoughtbot dotfiles](https://github.com/thoughtbot/dotfiles)
- [Awesome dotfiles](https://github.com/webpro/awesome-dotfiles)
