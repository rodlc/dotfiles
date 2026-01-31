---
description: Save session summary to Notion Tasks database
argument-hint: "[priority] [title]"
---

Save structured summaries to Notion Tasks using plan-first workflow.

## Workflow

1. **List Recent Plans**: Find all plans modified < 5h in `~/.claude/plans/`
2. **Update Plan**: Finalize plan with session changes (Actions, Résultat, Learnings)
3. **Create Notion Task**: Create task with properties
4. **Append Code Block**: Add plan content as code block (box-drawing renders correctly)
5. **Update Marker**: Append `<!-- notion:posted:{page_id}:mtime:{timestamp} -->` to plan
6. **Output**: Show Notion task URL

**Principles**:
- Plan file = source of truth
- Notion = shell + code block content
- No local export (plan file is the archive)

## Plan Detection

**Time Window**: 5h (18000s) - aligned with ccline quota window

**Logic**:
```bash
# List recent plans (< 5h)
find ~/.claude/plans -name "*.md" -mmin -300

# For each plan, check marker
grep "notion:posted" $plan || echo "unposted"

# If marker exists, compare mtime
plan_mtime=$(stat -f %m $plan)
marker_mtime=$(grep -oP 'mtime:\K\d+' $plan)
[ $plan_mtime -gt $marker_mtime ] && echo "modified"
```

## Plan Structure (Retroactive)

When generating a retroactive plan (no existing plan found):

```markdown
# {Title}

**Date** : {YYYY-MM-DD}
**Type** : 🔧 Setup | 🔍 Research | 🔬 Analysis | 💻 Learning

---

## Contexte
{Why this session happened}

## Actions réalisées
- {bullet points of key actions}

## Résultat
{Outcome, files modified, metrics}

## Learnings
- {Cross-session insights}

<!-- notion:posted:{page_id}:mtime:{timestamp} -->
```

**Type Detection**:
- 🔧 Setup: Configuration, tooling, infrastructure
- 🔍 Research: Investigation, hypothesis testing, calculations
- 🔬 Analysis: Comparative analysis, benchmarking, positioning
- 💻 Learning: Concepts, definitions, educational content
- **Default to 🔧 if unclear**

## Task Properties

- **Task**: Short title in EN, use | or / for sub-elements (override with `$ARGUMENTS`)
- **Priority**: Quick (~5min) | D2 (~30min) | W5 (~2h) | Scheduled | Reminder | Errand
- **Do date**: Today
- **Done**: Yes if complete, No otherwise
- **Project/Area**: Link if found via search, empty otherwise

**Title Examples**:
- ✅ "🔧 Claude Code | Setup"
- ✅ "🔍 PER * PTZ"
- ✅ "🔬 Obat / PlayPlay / Alan"
- ❌ "Setup optimisé Claude Code - Terminal + Workflow /notion"

## Title Generation

**Règle** : Le titre Notion dérive du slug du fichier staging.

**Process** :
1. Générer slug depuis `# Title` du plan : lowercase, `-` pour espaces
2. Humaniser pour titre Notion : capitaliser, séparer en 2 parties
3. Format : `{emoji} {Thème} | {Détail}`

**Exemples** :
| Slug | Titre Notion |
|------|--------------|
| `mcp-memory-quality` | 🔧 MCP Memory \| Quality |
| `tiny-house-chassis-analysis` | 🔬 Tiny House \| Chassis |
| `vinci-email-correction` | 🔧 Vinci \| Email correction |

## Content Templates

**Deleted** - Plans follow CLAUDE.md formatting rules directly.
Type detection (🔧/🔍/🔬/💻) still used for title emoji only.

## Content Strategy

**Le plan EST le contenu final** - pas de reformatage.

1. Create task shell (properties only)
2. Append plan content as code block with chunked rich_text:
   ```json
   {
     "object": "block",
     "type": "code",
     "code": {
       "rich_text": [
         {"type": "text", "text": {"content": "<chunk 1 - max 2000 chars>"}},
         {"type": "text", "text": {"content": "<chunk 2 - max 2000 chars>"}},
         // ... up to 100 chunks (200k chars max)
       ],
       "language": "plain text"
     }
   }
   ```
3. Update marker in plan file

**Chunking Algorithm**:
```python
# Split content into 2000-char chunks
content = plan_file_content
chunks = []
while content:
    chunks.append(content[:2000])
    content = content[2000:]
rich_text = [{"type": "text", "text": {"content": c}} for c in chunks]
```

**Rationale**:
- Box-drawing renders correctly in monospace code blocks
- Notion allows 100 rich_text elements per block (2000 chars each = ~200k total)
- Single code block with chunked array avoids multiple separate blocks

## Marker System

**Format**: `<!-- notion:posted:{page_id}:mtime:{unix_timestamp} -->`

**Location**: End of plan file (after content)

**Behavior**:

| Situation | Action | API Calls |
|-----------|--------|-----------|
| No marker | Create task + append code block | 2 |
| Marker + plan modified | Update task + replace code block | 2 |
| Marker + plan unchanged | Skip (idempotent) | 0 |

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
📋 Content appended as code block
```

**On Notion failure**:
```
⚠️ Notion task creation failed
📋 Plan preserved in: ~/.claude/plans/{plan}.md
```
