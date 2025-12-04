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
4. **Setup environment** (create `~/.env` from template if not exists)
5. **Install plugins** (zsh-autosuggestions, zsh-syntax-highlighting)
6. **Install security hooks** (Gitleaks pre-commit)

After installation:
1. Edit `~/.env` with your API keys
2. Restart your terminal or run `source ~/.zshrc`

## Structure

```
dotfiles/
├── install.sh              # Installation script (idempotent)
├── .env.template           # Environment variables template (copied to ~/.env)
├── .pre-commit-config.yaml # Gitleaks security config
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

### Secrets Management

**Workflow**:
1. `.env.template` is **versioned** (safe placeholders only)
2. `install.sh` copies it to `~/.env` (local, not versioned)
3. You edit `~/.env` with real API keys
4. Git **ignores** `~/.env` automatically (see `.gitignore`)

**Why this approach?**
- ✅ No manual copy: `install.sh` does it for you
- ✅ Template shows what's needed: clear documentation
- ✅ Never commit secrets: `.gitignore` protects `.env`, `secrets`, `*.secret`
- ✅ Idempotent: won't overwrite existing `~/.env`

**SSH keys**: `config` file references keys, but keys themselves stay in `~/.ssh/` (never versioned)

### Pre-commit Hooks

[Gitleaks](https://github.com/gitleaks/gitleaks) scans for hardcoded secrets before each commit (auto-installed by `install.sh`).

To skip temporarily: `SKIP=gitleaks git commit -m "message"`

**References**:
- [Dotfiles security best practices](https://medium.com/@instatunnel/why-your-public-dotfiles-are-a-security-minefield-fc9bdff62403)
- [Gitleaks pre-commit guide](https://medium.com/@ibm_ptc_security/securing-your-repositories-with-gitleaks-and-pre-commit-27691eca478d)
- [Beyond .env files (2025)](https://medium.com/@instatunnel/beyond-env-files-the-new-best-practices-for-managing-secrets-in-development-b4b05e0a3055)

## Notion Integration

Claude Code connects to Notion for task management. Configuration in `claude/CLAUDE.md` includes:
- Tasks database ID
- Projects database ID
- Areas database ID

Use `/notion` command in Claude Code to save session summaries.

## Daily Workflow

**Save config changes**:
```bash
df-save        # Commit and push all dotfiles changes
df-status      # Check uncommitted changes
dotfiles       # cd to dotfiles repo
```

The global git hook will remind you if dotfiles have uncommitted changes when you commit in other repos.

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
