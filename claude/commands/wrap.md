---
description: Wrap up session - recap, save to Notion, memorize, exit
argument-hint: "[priority]"
---

Wrap up this session by:
1. Finalizing the plan with progress
2. Saving to Notion
3. Extracting learnings to Memory
4. Syncing repos and exiting

## Workflow

1. Execute `/recap` - Finalize plan with session progress
2. Execute `/notion $ARGUMENTS` - Post to Notion
3. Execute `/memorize` - Extract and store learnings
4. Cleanup: `curl -X POST http://127.0.0.1:4242/api/manage/cleanup-duplicates`
5. Quality check: `curl http://127.0.0.1:4242/api/quality/distribution`
6. Auto-sync repos:
   - Dotfiles: commit & push if dirty
   - Workspace: commit & push if dirty
7. Display: "✅ Wrap-up complete. Type /exit or Ctrl+D to quit."

## Usage

- `/wrap` - Full wrap with Quick priority
- `/wrap D2` - Full wrap with D2 priority
