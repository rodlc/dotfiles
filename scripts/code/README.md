# Code Scripts

Git operations, config management, and credential sync.

## Scripts

### Git Operations

#### git-fetch-background.sh
Async git fetches with cache for dotfiles + workspace.

**Usage:**
```bash
./git-fetch-background.sh
```

**Features:**
- Background fetches
- Cache to avoid redundant operations
- Handles multiple repos

**Triggered by:** Git hooks, cron, or manual.

---

### Bitwarden Credential Sync

#### bw-pull
Sync Bitwarden → local (env + SSH keys).

**Usage:**
```bash
./bw-pull
```

**Synced:**
- `.env` files
- SSH keys
- API tokens

**Backend:** `rbw` (Rust Bitwarden CLI) for env, `bw` for SSH.

---

#### bw-push
Sync local → Bitwarden (env + SSH keys).

**Usage:**
```bash
./bw-push
```

**Updates Bitwarden with:**
- Local `.env` changes
- New SSH keys
- Updated tokens

---

#### bw-status
Check Bitwarden sync state.

**Usage:**
```bash
./bw-status
```

**Shows:**
- Last sync time
- Unlock status
- Sync conflicts

---

### Support Files

#### .bw-lib.sh
Shared functions for bw-pull/push/status.

**Functions:**
- `ensure_rbw` - Check rbw is unlocked
- `sync_env` - Sync .env files
- `sync_ssh` - Sync SSH keys

**Not meant to be run directly.**

---

## Workflow

### Daily (automated)
```bash
git-fetch-background.sh  # Keep repos up to date
```

### As needed (manual)
```bash
bw-pull                  # Pull credentials from Bitwarden
bw-push                  # Push credentials to Bitwarden
bw-status                # Check sync state
```
