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
2. Execute /memorize - extract and store learnings
3. Execute /consolidate-memory daily - quick consolidation
4. Execute ws-push - sync workspace state
5. Confirm all saves completed
6. Display: "✅ Wrap-up complete. Type /exit or Ctrl+D to quit."

## Usage

- `/wrap` - Memorize + Notion (Quick priority, inferred title) + exit
- `/wrap D2` - Memorize + Notion with D2 priority + exit
- `/wrap W5 "Feature implementation"` - Full specification
