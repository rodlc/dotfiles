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
├── .env.example            # Secrets example (→ ~/.env)
├── .git-hooks/             # Global git hook (dotfiles reminder)
├── aliases, zshrc, gitconfig, irbrc, pryrc, rspec, config
├── zed/                    # Zed editor configs
└── claude/                 # Claude Code configs + commands + MCPs
    ├── .mcp.json           # MCP servers template (GitHub, Notion, Slack, Gmail, Rails)
    ├── mcp-sync.sh         # Sync MCPs: install/export/diff
    ├── settings.json       # Permissions, hooks, model
    ├── hooks/              # PreToolUse hooks (safe-bash.sh)
    ├── skills/             # Skills (playwright.md, terminal-title/)
    ├── commands/           # Commands (notion.md, summarize.md)
    ├── statusline.sh       # Status line script ($36 quota tracking)
    └── CLAUDE.md           # Global instructions (Notion IDs, preferences)
```

## Security

**Secrets**: `.env.example` (versioned) → auto-copied to `~/.env` (gitignored). Edit `~/.env` with real API keys. SSH keys stay in `~/.ssh/`.

**Pre-commit**: [Gitleaks](https://github.com/gitleaks/gitleaks) scans for secrets before each commit. Skip with `SKIP=gitleaks git commit -m "msg"`.

## MCP Servers

Claude Code MCP (Model Context Protocol) servers are managed via version-controlled templates with environment variable substitution.

**Active servers** (6):
- **GitHub** (HTTP): Issues, PRs, repos, code search
- **Notion** (stdio): Pages, databases, blocks
- **Slack** (stdio): Messages, channels, threads
- **Gmail×2** (stdio): Email for rodlecoent + rodolphe.lecoent
- **Rails MCP** (stdio): Rails project analysis

**Configuration files**:
```
~/.claude.json              # Active config (82KB: MCPs + OAuth + prefs)
~/Code/rodlc/dotfiles/
  └── claude/.mcp.json      # Template (versioned, with ${VARIABLES})
~/.env                      # Secrets (CODE_DIR, tokens)
```

**Sync commands**:
```bash
mcp-sync install   # Install MCPs from dotfiles → ~/.claude.json
mcp-sync export    # Export ~/.claude.json → dotfiles template
mcp-sync diff      # Compare dotfiles vs active config
```

**Variables in template**:
- `${CODE_DIR}` → `/Users/rodlecoent/Code` (project paths)
- `${HOME}` → `/Users/rodlecoent` (home paths)
- `${GITHUB_TOKEN}`, `${NOTION_API_TOKEN}`, etc. → API tokens

**Workflow**:
1. Edit `claude/.mcp.json` template (add/remove servers)
2. Run `mcp-sync install` to apply changes
3. Restart Claude Code
4. Run `df-save` to version changes

## Daily Workflow

**Save config changes**:
```bash
df-save        # Commit and push all dotfiles changes
df-status      # Check uncommitted changes
dotfiles       # cd to dotfiles repo
mcp-sync diff  # Check MCP config drift
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
