# Dotfiles

Personal development environment configuration for macOS. Originally inspired by [Le Wagon dotfiles](https://github.com/lewagon/dotfiles), now fully custom.

## Quick Start

```bash
cd ~/Code
git clone git@github.com:rodlc/dotfiles.git
cd dotfiles
./install.sh            # dotfiles: standalone machine
./install.sh workspace  # + Claude Code + workspace
./install.sh mcp        # + MCP servers + launchd + memory
```

## Install Tiers

| Tier | What | Use case |
|------|------|----------|
| `dotfiles` | Shell + Git + Zed + Brew + SSH | One-off machine, no dependencies |
| `workspace` | + Claude Code CLI + workspace clone + config symlinks | Temporary machine |
| `mcp` | + MCP servers + launchd services + memory hooks | Permanent machine |

Each tier includes the previous. Re-run anytime (idempotent).

**Tier dotfiles** installs:
- Homebrew + packages (Brewfile)
- Language runtimes via mise (Node, Python, Ruby, Go, Bun)
- Shell config (zsh, starship prompt, aliases)
- Git config (aliases, settings — identity generated from `~/.env`)
- SSH config + Zed editor
- Pre-commit hooks (Gitleaks) + global git hook
- macOS defaults (optional prompt)

**Tier workspace** adds:
- Claude Code CLI
- Bitwarden setup + secrets sync (`~/.env`, SSH keys)
- Workspace clone (private repo with Claude config)
- Symlinks: CLAUDE.md, settings, commands, hooks, rules, skills

**Tier mcp** adds:
- MCP server builds (Notion, Gmail, Memory, Raycast)
- MCP config expansion (template → `~/.claude.json`)
- Launchd services (memory HTTP server, backup)
- Memory hooks (session tracking)
- Ollama model pull, battery config

## Structure

```
dotfiles/
├── install.sh              # Tiered installer (dotfiles|workspace|mcp)
├── .env.example            # Secrets template (→ ~/.env)
├── .git-hooks/             # Global git hook (dotfiles reminder)
├── config/                 # → ~/.config/ (XDG app configs)
│   ├── git/config          #   Git aliases, push, identity includes
│   ├── mise/config.toml    #   Language runtime versions
│   ├── pry/pryrc           #   Pry custom prompt
│   ├── starship.toml       #   Prompt config
│   ├── zed/                #   Zed editor settings + keymap
│   └── zsh/                #   Aliases, plugins, conf.d modules, scripts
├── home/                   # → ~/.<name> (home dir dotfiles)
│   ├── finicky.js          #   Browser router
│   ├── irbrc, rspec        #   Ruby config
│   ├── ssh/config          #   Multi-identity SSH
│   ├── zprofile            #   Login shell (brew + mise shims)
│   └── zshrc               #   Main shell config
├── scripts/                # Utility scripts
│   ├── code/               #   Bitwarden tools, git fetch
│   ├── productivity/       #   MCP memory HTTP
│   └── system/             #   Brew, cleanup, backup
├── launchd/                # Ollama plist
├── Brewfile                # Homebrew packages
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
