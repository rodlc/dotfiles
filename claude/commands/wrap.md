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
3. Execute cleanup_duplicates() - remove exact duplicates
4. Quick quality snapshot:
   - `analyze_quality_distribution` (top 3 / bottom 3)
   - If bottom 3 contains memories from session → warning
5. Sync status check (non-blocking):
   - Run `git -C ~/Code/rodlc/dotfiles status --porcelain`
   - Run `git -C ~/Code/rodlc/workspace status --porcelain`
   - Display results:
     - Clean: `✅ Dotfiles: clean` / `✅ Workspace: clean`
     - Dirty: `⚠️ Dotfiles: N uncommitted → df-push` / `⚠️ Workspace: N uncommitted → ws-push`
6. Confirm all saves completed
7. Display: "✅ Wrap-up complete. Type /exit or Ctrl+D to quit."

## Usage

- `/wrap` - Memorize + Notion (Quick priority, inferred title) + exit
- `/wrap D2` - Memorize + Notion with D2 priority + exit
- `/wrap W5 "Feature implementation"` - Full specification
