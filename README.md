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
4. **Clone & build MCP servers** (Notion, Gmail, Slack, Rails MCP to `~/Code`)
5. **Configure MCPs** (merge template into `~/.claude.json`)
6. **Setup environment** (create `~/.env` from template if not exists)
7. **Install plugins** (zsh-autosuggestions, zsh-syntax-highlighting)
8. **Install security hooks** (Gitleaks pre-commit)

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
├── scripts/                # Utility scripts
│   └── bw-*                # Bitwarden secrets management (pull, push, status, bootstrap)
└── claude/                 # Claude Code configs + commands + MCPs
    ├── .mcp.json           # MCP servers template (GitHub, Notion, Slack, Gmail, Rails)
    ├── install-mcp-servers.sh  # Clone & build MCP repos from GitHub
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

## Secrets & Context Management

### Bitwarden Secrets

Secrets are stored in Bitwarden and synced to `~/.env` via rbw (agent-based, no session management).

**First-time setup**:
```bash
brew install rbw bitwarden-cli
rbw config set email your@email.com
rbw config set base_url https://vault.bitwarden.eu  # if EU server
rbw login
bw-bootstrap  # Creates "Dotfiles Env" + "MCP Memory GPG" items
```

**Daily usage**:
```bash
bw-pull       # Pull secrets from Bitwarden → ~/.env (via rbw)
bw-push       # Push ~/.env → Bitwarden (via bw CLI)
bw-status     # Check sync status (via rbw)
```

### Workspace (Private Repo)

Private workspace for AI context (plans, memory, notes) lives in: `rodlc/workspace`.

**Structure**:
```
~/Code/rodlc/workspace/
├── claude/                  # Claude Code context
│   ├── memory/             # Encrypted MCP Memory backups
│   │   └── memories.json.gpg
│   └── plans/              # Plans (synced with ~/.claude/plans)
├── cursor/                  # (Future) Cursor IDE configs
├── notes/                   # (Future) Project notes, scratchpad
└── scripts/                 # Sync utilities
```

**First-time setup**:
```bash
cd ~/Code/rodlc
git clone git@github.com:rodlc/workspace.git
cd workspace
./scripts/setup
```

**Daily workflow**:
```bash
workspace-sync        # Full sync (memory + plans + git push/pull)
workspace-status      # Check status
workspace-push        # Push local → remote
workspace-pull        # Pull remote → local
```

**Cross-machine sync**:
1. **Machine A**: `workspace-sync` (auto-commits & pushes)
2. **Machine B**: `workspace-pull` (pulls & imports)

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
4. Run `df-push` to version changes

## Raycast MCP

Raycast AI uses the same MCP servers for productivity workflows (quick queries, email, Slack).

**Active servers** (5):
- **Notion** (stdio): Tasks, notes, databases
- **Gmail-pro** (stdio): rodlecoent@gmail.com
- **Gmail-perso** (stdio): rodolphe.lecoent@gmail.com
- **Memory** (npx): Persistent context between sessions
- **Filesystem** (npx): Read/analyze local files

**Installation** (manual via Raycast UI):
```
Cmd+Space → "Install Server"
Fill: Name, Command, Args, Env
Test: @notion, @gmail-pro, @filesystem
```

**Server locations**: Shared from `~/Code/` (cloned by `install-mcp-servers.sh`)

**Philosophy**:
- **Raycast** = Productivity (email, files, quick queries)
- **Claude Code** = Dev workflow (GitHub, Rails MCP)

## Daily Workflow

**Dotfiles management**:
```bash
df-push        # Commit and push all dotfiles changes
df-pull        # Pull latest dotfiles from remote
df-status      # Check uncommitted changes
dotfiles       # cd to dotfiles repo
mcp-sync diff  # Check MCP config drift
```

**Secrets & workspace sync**:
```bash
bw-pull            # Pull secrets from Bitwarden
workspace-push     # Push workspace (memory + plans) to Git
workspace-pull     # Pull workspace from Git
```

The global git hook will remind you if dotfiles have uncommitted changes when you commit in other repos.

## Customization

Edit configs directly (via symlinks):
- `~/.zshrc` → aliases, PATH
- `~/.config/zed/settings.json` → theme, fonts
- `~/.claude/CLAUDE.md` → Notion IDs, preferences
- `~/.env` → API keys

Re-run `./install.sh` anytime (idempotent).

## Language Version Policy

Use **LTS/stable versions exclusively** via version managers. Brewfile excludes language packages to prevent auto-upgrades.

| Language | Manager | Install | Default |
|----------|---------|---------|---------|
| Node.js | nvm | `nvm install --lts` | `nvm alias default lts/*` |
| Python | pyenv | `pyenv install <stable>` | `pyenv global <version>` |
| Ruby | rbenv | `rbenv install <stable>` | `rbenv global <version>` |

**Why?** Homebrew's `brew upgrade` auto-upgrades languages (like Node v25), breaking dependencies. Version managers allow pinning and easy switching.

**MOTD warning**: Shell startup warns if Homebrew language binaries detected.

## References

- [Thoughtbot dotfiles](https://github.com/thoughtbot/dotfiles) - Inspiration
- [Awesome dotfiles](https://github.com/webpro/awesome-dotfiles) - Curated list
- [Dotfiles security](https://medium.com/@instatunnel/why-your-public-dotfiles-are-a-security-minefield-fc9bdff62403) - Best practices
