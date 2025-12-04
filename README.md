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
├── install.sh              # Auto-install all tools + configs
├── .env.template           # Secrets template (→ ~/.env)
├── .git-hooks/             # Global git hook (dotfiles reminder)
├── aliases, zshrc, gitconfig, irbrc, pryrc, rspec, config
├── zed/                    # Zed editor configs
└── claude/                 # Claude Code configs + commands
```

## Security

**Secrets**: `.env.template` (versioned) → auto-copied to `~/.env` (gitignored). Edit `~/.env` with real API keys. SSH keys stay in `~/.ssh/`.

**Pre-commit**: [Gitleaks](https://github.com/gitleaks/gitleaks) scans for secrets before each commit. Skip with `SKIP=gitleaks git commit -m "msg"`.

## Daily Workflow

**Save config changes**:
```bash
df-save        # Commit and push all dotfiles changes
df-status      # Check uncommitted changes
dotfiles       # cd to dotfiles repo
```

The global git hook will remind you if dotfiles have uncommitted changes when you commit in other repos.

## Customization

Edit configs directly (via symlinks):
- `~/.zshrc` → aliases, PATH
- `~/.config/zed/settings.json` → theme, fonts
- `~/.claude/CLAUDE.md` → Notion IDs, preferences
- `~/.env` → API keys

Re-run `./install.sh` anytime (idempotent).

## References

- [Thoughtbot dotfiles](https://github.com/thoughtbot/dotfiles) - Inspiration
- [Awesome dotfiles](https://github.com/webpro/awesome-dotfiles) - Curated list
- [Dotfiles security](https://medium.com/@instatunnel/why-your-public-dotfiles-are-a-security-minefield-fc9bdff62403) - Best practices
