# System Scripts

OS maintenance, cleanup, and system-level fixes.

## Scripts

### brew-fix-permissions
Fix Homebrew permissions for multi-user setups.

**Usage:**
```bash
./brew-fix-permissions
```

**When:** After Homebrew installs/updates with permission errors.

---

### cleanup-caches.sh
Clean macOS browser caches safely.

**Usage:**
```bash
./cleanup-caches.sh
```

**Cleaned:**
- Safari caches
- Chrome caches
- Firefox caches

**When:** Monthly, or when disk space is low.

---

### cleanup-login-items.sh
Remove unwanted login items (Ollama, background tasks).

**Usage:**
```bash
./cleanup-login-items.sh
```

**When:** After installing apps that auto-start.

---

### cleanup-old-hooks.sh
Remove obsolete custom hooks after mcp-memory-service migration.

**Usage:**
```bash
./cleanup-old-hooks.sh
```

**When:** One-time after MCP Memory migration.

---

## Frequency

| Script | Frequency |
|--------|-----------|
| brew-fix-permissions | As needed (permission errors) |
| cleanup-caches.sh | Monthly |
| cleanup-login-items.sh | As needed (after installs) |
| cleanup-old-hooks.sh | One-time (migration) |
