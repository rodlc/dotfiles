---
description: Post session plan to Notion Tasks
argument-hint: "[--all] [priority]"
---

Post the current session plan to Notion Tasks.

## Usage

- `/notion` - Post current session plan
- `/notion --all` - Scan and post all recent plans (< 5h)
- `/notion D2` - Post with D2 priority

## Workflow (default)

1. **Get session plan**: From system prompt or most recent in ~/.claude/plans/
2. **Create Notion task**:
   - Title: Derived from plan `# Title`
   - Priority: From args or "Quick"
   - Do date: Today
   - Done: ✅ if "Statut: ✅" in Résultat, else ❌
3. **Append content**: Plan as single code block (server auto-chunks)
4. **Update marker**: `<!-- notion:posted:{page_id}:mtime:{timestamp} -->`

## Workflow (--all)

1. Find all plans: `find ~/.claude/plans -name "*.md" -mmin -300`
2. Filter: Skip if marker exists AND plan unchanged
3. Process each: Create/update Notion task

## Title Generation

From plan `# Title`:
- `# MCP Memory Quality` → `🔧 MCP Memory | Quality`
- `# Tiny House Chassis Analysis` → `🔬 Tiny House | Chassis`

## Task Properties

- **Task**: `{emoji} {Theme} | {Detail}`
- **Priority**: Quick | D2 | W5 | Scheduled
- **Do date**: Today
- **Done**: ✅ if "Statut: ✅" in Résultat, else ❌

## Content Strategy

**Le plan EST le contenu final** - pas de reformatage.

1. Create task shell (properties only)
2. Append plan content as single code block:
   ```json
   {
     "object": "block",
     "type": "code",
     "code": {
       "rich_text": [{"type": "text", "text": {"content": "<full plan content>"}}],
       "language": "plain text"
     }
   }
   ```
3. Update marker in plan file

**⚠ DO NOT chunk manually** — the MCP server auto-chunks rich_text
(>2000 chars) server-side. Send full content in a single rich_text item.

## Marker System

**Format**: `<!-- notion:posted:{page_id}:mtime:{unix_timestamp} -->`

**Location**: End of plan file (after content)

**Behavior**:

| Situation | Action | API Calls |
|-----------|--------|-----------|
| No marker | Create task + append code block | 2 |
| Marker exists | Delete old blocks + append new | 2-3 |
| Marker exists but page 404 | Fallback: create new task | 2 |

### Update Flow (when marker exists)

1. Extract page_id: `grep -o 'posted:[^:]*' {plan} | cut -d: -f2`
2. Get existing blocks: `notion_retrieve_block_children(page_id)`
3. Delete code blocks only: `notion_delete_block(block_id)` for each code block
4. Append new code block with plan content
5. Update marker: `<!-- notion:posted:{page_id}:mtime:{new_timestamp} -->`

**Error handling:** If page returns 404, remove marker and CREATE new task.

**Content sync via code block** - shell properties + plan content as code block

## Error Handling

**Two API calls** (create/update task + append code block):
- Success → Show Notion URL
- Failure → Warn and preserve plan file

**No retry needed** - code block append is idempotent

## Style Guide

**Emojis**: 🔧 Setup | 🔍 Research | 🔬 Analysis | 💻 Learning | 🔖 Tasks | 🧮 Data

**Language**:
- Titles: EN
- Content: Match discussion language

**Tables**: Use for comparisons (≥2 options), structured data, risks, benchmarks

**Closing**: Research/Analysis = quote/summary | Technical = next actions

**Concise**: Actionable info only, code refs as file:line

## Technical Notes

**Property Formats** (critical for API):
- Area/Project: Single URL string, NOT array
  - ✅ `"Area": "https://www.notion.so/6d9b458c..."`
  - ❌ `"Area": ["https://www.notion.so/6d9b458c..."]`
- Date: Use `date:PropertyName:start`, `date:PropertyName:is_datetime`
- Done: Use `"__YES__"` or `"__NO__"`

**Search Strategy**:
1. Identify keyword from plan content (e.g., "Code", "Finance")
2. Search Areas/Projects with `mcp__notion__notion_search`
3. Use URL directly in properties (no brackets)

**Common Errors**:
- "Invalid input" → Check string vs array format
- Area not found → Leave empty, user links manually
- Duplicate tasks → Search first before creating

**Output Format**:
```
✅ Notion task created: https://notion.so/...
📋 Content appended
```

or

```
✅ Notion task updated: https://notion.so/...
📋 Content synced (1 block replaced)
```

**On Notion failure**:
```
⚠️ Notion task creation failed
📋 Plan preserved in: ~/.claude/plans/{plan}.md
```

## Required API Calls

Execute in sequence, verify each completion:

1. `notion_create_database_item` with:
   - Task: title
   - Priority: from args or "Quick"
   - **Do date: today's date** (critical)
   - Done: checkbox false
2. `notion_append_block_children` with plan content as single code block (no manual chunking)
3. Update plan file with `<!-- notion:posted:{page_id}:mtime:{timestamp} -->` marker
