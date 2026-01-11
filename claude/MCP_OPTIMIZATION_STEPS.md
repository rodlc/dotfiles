# MCP Optimization - Post-Configuration Steps

## Changes Applied

✅ **Notion**: Tool filtering enabled (6/17 tools)
✅ **Slack**: Disabled
✅ **Rails-mcp**: Disabled
✅ **GCal**: Consolidated to single instance with multi-account support

**Expected token savings**: ~17k tokens (8.5%)

---

## Next Steps (After Claude Code Restart)

### 1. Add GCal accounts to unified instance

Use the `manage-accounts` tool in Claude Code:

```
Please add my two Google Calendar accounts:
- action: "add", account_id: "rodlecoent"
- action: "add", account_id: "rodolphe"
```

### 2. Verify functionality

Test calendar access:
```
Show me today's events from both my accounts
```

### 3. Cleanup old directories (optional)

Once verified working:
```bash
rm -rf ~/.gcal-mcp-rodlecoent ~/.gcal-mcp-rodolphe
```

### 4. Check token usage

```
/context
```

Expected: MCP tools < 60k tokens (was 65k)

---

## Rollback (if needed)

```bash
cp ~/Code/rodlc/dotfiles/claude/.mcp.json.backup ~/Code/rodlc/dotfiles/claude/.mcp.json
rm -rf ~/.gcal-mcp
```
