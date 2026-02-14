# Productivity Scripts

Automation and developer workflow tools.

## Scripts

### mcp-memory-http-start.sh
Start MCP Memory HTTP server (launchd wrapper).

**Usage:**
```bash
./mcp-memory-http-start.sh
```

**What it does:**
- Starts `mcp-memory-service` HTTP server
- Configured for Claude Code hooks
- Runs via launchd (background daemon)

**Port:** 4242 (default)

**Connection:**
```bash
# Test connection
curl http://localhost:4242/health

# Used by Claude Code memory hooks
# Connection configured in ~/.claude/config.json
```

**When:** Session init (via launchd), or manual restart.

---

## Workflow

### Automated (launchd)
The MCP Memory server starts automatically via launchd on login.

### Manual restart
```bash
./mcp-memory-http-start.sh
```

Use when:
- Server crashed
- Config changes
- Memory corruption issues
