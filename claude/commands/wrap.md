---
description: Wrap up session - memorize learnings, save to Notion, exit
argument-hint: "[priority] [title]"
---

Wrap up this session by:
1. Saving summary to Notion + local file
2. Extracting cross-session learnings to Memory
3. Exiting cleanly

## Workflow

1. Execute /notion with arguments: `$ARGUMENTS`
2. Execute /memorize - extract and store learnings (auto-rated +1)
3. Cleanup duplicates: `curl -X POST http://127.0.0.1:4242/api/manage/cleanup-duplicates`
4. Quality distribution: `curl http://127.0.0.1:4242/api/quality/distribution`
5. Quick quality snapshot:
   - `analyze_quality_distribution` (top 3 / bottom 3)
   - If bottom 3 contains memories from session → warning
6. Auto-sync repos (non-blocking):
   - Dotfiles: Check if dirty with `git -C ~/Code/rodlc/dotfiles status --porcelain`
     - If dirty: `git -C ~/Code/rodlc/dotfiles add -A && git -C ~/Code/rodlc/dotfiles commit -m "wrap: session sync" && git -C ~/Code/rodlc/dotfiles push`
   - Workspace: Check if dirty with `git -C ~/Code/rodlc/workspace status --porcelain`
     - If dirty: `git -C ~/Code/rodlc/workspace add -A && git -C ~/Code/rodlc/workspace commit -m "wrap: session sync" && git -C ~/Code/rodlc/workspace push`
   - Display results:
     - Synced: `✅ Dotfiles: synced` / `✅ Workspace: synced`
     - Clean: `✅ Dotfiles: clean` / `✅ Workspace: clean`
     - Failed: `⚠️ Dotfiles: sync failed` / `⚠️ Workspace: sync failed`
7. Confirm all saves completed
8. Display: "✅ Wrap-up complete. Type /exit or Ctrl+D to quit."

## Usage

- `/wrap` - Memorize + Notion (Quick priority, inferred title) + exit
- `/wrap D2` - Memorize + Notion with D2 priority + exit
- `/wrap W5 "Feature implementation"` - Full specification
