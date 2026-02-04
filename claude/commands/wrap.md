---
description: Wrap up session - save to Notion, memorize, sync git
argument-hint: "[priority]"
---

Wrap up session by saving context, extracting learnings, and syncing repos.

**IMPORTANT:** This command requires edit mode. If in plan mode, use `/recap` first.

## Guard: Check Mode

Check system-reminder for "Plan mode is active":
- If present → output: "⚠ Edit mode requis. Lance `/recap` d'abord pour finaliser le plan, puis Shift+Tab pour approuver et passer en edit mode."
- If not → proceed with workflow below

## Workflow (edit mode only)

1. Execute `/notion $ARGUMENTS` - Post to Notion → **capture Notion URL from output**
2. Execute `/memorize` - Extract and store learnings
3. **Store session stub** with minimal metadata and pointers:
   - Plan path: from system-reminder or read latest plan in ~/.claude/plans/
   - Notion URL: from step 1 output
   - Template: `[session-stub] {plan_title}\nDate: {date}\nPlan: {plan_path}\nNotion: {notion_url}\nTopics: {topics}\nOutcome: {status}\nTags: session-stub, {project}, {topics}`
   - Use: `mcp__memory-service__store_memory` with type: `session-stub`
4. Cleanup: `curl -X POST http://127.0.0.1:4242/api/manage/cleanup-duplicates`
5. Quality check: `curl http://127.0.0.1:4242/api/quality/distribution`
6. Auto-sync repos:
   - Dotfiles: commit & push if dirty
   - Workspace: commit & push if dirty
7. Display: "✅ Wrap-up complete. Type /exit or Ctrl+D to quit."

## Usage

- `/wrap` - Full wrap with Quick priority
- `/wrap D2` - Full wrap with D2 priority

## Typical workflow

```
# 1. En plan mode
/recap          → update plan, propose approbation
[Shift+Tab]     → approve, passe en edit mode

# 2. En edit mode
/wrap           → notion + memorize + git sync
```
