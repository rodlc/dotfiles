# Dotfiles Scripts

Generic, reusable automation scripts (public).

## Structure

```
scripts/
├── system/          # OS maintenance, cleanup
├── code/            # Git, dev tools, credential sync
└── productivity/    # Automation, developer workflows
```

## Categories

### System
OS-level maintenance and cleanup tasks.
- **Frequency:** Periodic (weekly/monthly) or as needed
- **Examples:** Cache cleanup, permission fixes, login items

See [system/README.md](system/README.md)

---

### Code
Git operations, config management, credential sync.
- **Frequency:** Daily (automated via hooks/cron)
- **Examples:** Git fetch, symlink sync, Bitwarden sync

See [code/README.md](code/README.md)

---

### Productivity
Developer workflow automation.
- **Frequency:** Session init (launchd) or manual
- **Examples:** MCP Memory server, session management

See [productivity/README.md](productivity/README.md)

---

## Private vs Public

| Location | Visibility | Content |
|----------|-----------|---------|
| `dotfiles/scripts/` | **Public** | Generic tools (this folder) |
| `workspace/scripts/` | **Private** | Personal data (SIRET, IBAN, clients) |

**Never commit workspace scripts to public repos.**

---

## Migration from ~/.claude/scripts/

Legacy scripts in `~/.claude/scripts/` are:
- **Campaign/consolidation scripts** (one-time MCP memory cleanup)
- **Should NOT migrate** to dotfiles (temporary, session-specific)
- **Archive after completion** of memory migration project

See migration plan in workspace/scripts/README.md
