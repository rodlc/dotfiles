# Dotfiles

Personal development environment configuration for macOS. Fork of [Le Wagon dotfiles](https://github.com/lewagon/dotfiles).

## Quick Start

```bash
cd ~/Code
git clone git@github.com:rodlc/dotfiles.git
cd dotfiles
./install.sh            # min: standalone machine
./install.sh claude     # + Claude Code + workspace
./install.sh full       # + MCP servers + launchd + memory
```

## Install Tiers

| Tier | What | Use case |
|------|------|----------|
| `min` | Shell + Git + Zed + Brew + SSH | One-off machine, no dependencies |
| `claude` | + Claude Code CLI + workspace clone + config symlinks | Temporary machine |
| `full` | + MCP servers + launchd services + memory hooks | Permanent machine |

Each tier includes the previous. Re-run anytime (idempotent).

**Tier min** installs:
- Homebrew + packages (Brewfile)
- Language runtimes via mise (Node, Python, Ruby, Go, Bun)
- Shell config (zsh, starship prompt, aliases)
- Git config (aliases, settings — identity generated from `~/.env`)
- SSH config + Zed editor
- Pre-commit hooks (Gitleaks) + global git hook
- macOS defaults (optional prompt)

**Tier claude** adds:
- Claude Code CLI
- Bitwarden setup + secrets sync (`~/.env`, SSH keys)
- Workspace clone (private repo with Claude config)
- Symlinks: CLAUDE.md, settings, commands, hooks, rules, skills

**Tier full** adds:
- MCP server builds (Notion, Gmail, Memory, Raycast)
- MCP config expansion (template → `~/.claude.json`)
- Launchd services (memory HTTP server, backup)
- Memory hooks (session tracking)
- Ollama model pull, battery config

## Structure

```
dotfiles/
├── install.sh              # Tiered installer (min|claude|full)
├── .env.example            # Secrets template (→ ~/.env)
├── .git-hooks/             # Global git hook (dotfiles reminder)
├── git/config              # Git config (identity generated at install)
├── ssh/config              # SSH config
├── zshrc, zprofile         # Shell entry points
├── zsh/                    # Aliases, plugins, conf.d modules
├── starship.toml           # Prompt config
├── zed/                    # Zed editor settings + keymap
├── mise/                   # Language runtime versions
├── scripts/                # Utility scripts
│   ├── code/               # Bitwarden tools (bw-pull, bw-push)
│   └── system/             # System maintenance (brew, cleanup)
├── launchd/                # System launchd plists (Ollama)
├── Brewfile                # Homebrew packages
├── ruby/                   # Ruby config (irbrc, rspec, pryrc)
├── finicky.js              # Browser router
├── terminal/               # Terminal.app profile
└── macos.sh                # macOS defaults
```

## Security

**Secrets**: `~/.env` (gitignored) stores API tokens. Synced via Bitwarden (`bw-pull` / `bw-push`).

**Pre-commit**: [Gitleaks](https://github.com/gitleaks/gitleaks) scans for secrets on every commit.

**Separation**: All Claude Code config (skills, commands, hooks, MCP templates) lives in the private workspace repo — never in this public dotfiles repo.

## Workspace (Private)

Private repo for Claude Code config, MCP servers, and encrypted memory: `rodlc/workspace`.

```
~/Code/rodlc/workspace/
├── .claude/                # Claude Code config (symlinked → ~/.claude/)
│   ├── commands/           # Slash commands
│   ├── skills/             # Skills (docx, pdf, posthog...)
│   ├── hooks/              # PreToolUse hooks
│   ├── rules/              # Project rules
│   └── .mcp.json           # MCP template (expanded by mcp-sync.sh)
├── mcp-servers/            # MCP source code (git submodules)
├── memory/                 # Encrypted backups (GPG)
└── scripts/                # Sync utilities
```

## Daily Workflow

```bash
# Dotfiles
df-push        # Commit and push all dotfiles changes
df-status      # Check uncommitted changes

# Secrets & workspace
bw-pull        # Pull secrets from Bitwarden → ~/.env
ws-push        # Push workspace (memory + plans)
ws-pull        # Pull workspace from remote
```

## References

- [Thoughtbot dotfiles](https://github.com/thoughtbot/dotfiles)
- [Awesome dotfiles](https://github.com/webpro/awesome-dotfiles)
