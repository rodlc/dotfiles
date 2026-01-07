---
description: Save session summary to Notion Tasks database
argument-hint: "[priority] [title]"
---

Save structured summaries to Notion Tasks using plan-first workflow.

## Workflow

1. **List Recent Plans**: Find all plans modified < 5h in `~/.claude/plans/`
2. **Process Each Plan** (all plans, not just current session):
   - No marker → Retry x3 → CREATE task + append content (2 APIs)
   - Marker + plan newer (mtime) → Retry x3 → DELETE old + CREATE new (3 APIs)
   - Marker + plan same/older → SKIP (idempotent, 0 API)
3. **Fallback**: If no plans found → Generate retroactive plan for current session + CREATE task
4. **Update Markers**: Append `<!-- notion:posted:{page_id}:mtime:{timestamp} -->` to each plan

**Principles**:
- Plan = source of truth (persisted locally before Notion)
- Auto-update idempotent (mtime comparison)
- Delete + Recreate strategy (3 APIs vs 12-32 for clearing children)
- Multi-plans → Multi-tasks
- Retry x3 with exponential backoff (2s, 4s) before fallback

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

## Content Templates

**Detect type, adapt structure. Number sections with 1️⃣ 2️⃣ 3️⃣**

### 🔧 Setup/Config
Context → Decisions → Summary (result, modified files, metrics) → Sources

### 🔍 Research
Title (CAPS) → Audit/Hypotheses → Calculations → Risks → Verdict → Roadmap → Quote

### 🔬 Analysis
Market Standard → Position → Tactics → Matrix (🥇🥈🥉) → One-sentence summary

### 💻 Learning
Bullet lists, definitions, minimal structure

**Default to 🔧 if type unclear**

## Markdown → Notion Conversion

| Markdown | Notion Block | Notes |
|----------|--------------|-------|
| `# Title` | Ignored | Used for Task title only |
| `## Section` | heading_2 | Main sections |
| `### Subsection` | heading_3 | Subsections |
| `- item` | bulleted_list_item | Unordered lists |
| `1. item` | numbered_list_item | Ordered lists |
| `\`\`\`code\`\`\`` | code | Truncate if > 500 chars |
| `| table |` | Preserved | Notion markdown tables |
| `---` | divider | Horizontal rules |

**Limits**:
- 2000 chars max per rich_text element
- 100 blocks max per append_block_children call
- If plan > 100 blocks, split by sections (rare)

## Marker System

**Format**: `<!-- notion:posted:{page_id}:mtime:{unix_timestamp} -->`

**Location**: End of plan file (after content)

**Behavior**:

| Situation | Action | API Calls |
|-----------|--------|-----------|
| No marker | Create task + append content | 2 |
| Marker + plan modified | Delete old + create new | 3 |
| Marker + plan unchanged | Skip (idempotent) | 0 |

**Why Delete+Recreate?**
- Notion API has no bulk "delete children"
- Clearing children = 1 retrieve + N deletes + 1 append = 12-32 APIs
- Delete page + recreate = 1 delete + 1 create + 1 append = 3 APIs
- **10x more economical** and conceptually cleaner

## Retry Strategy

**Exponential Backoff**:
- Attempt 1 → fail → wait 2s
- Attempt 2 → fail → wait 4s
- Attempt 3 → fail → Fallback to Downloads

**Applied to**:
- Create task (mcp__notion__notion_create_database_item)
- Append content (mcp__notion__notion_append_block_children)
- Delete task (mcp__notion__notion_delete_page)

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

**Timeout Fallback**:
If ANY Notion MCP call fails after 3 retries (timeout, 404, rate limit):
1. Infer concise filename from plan title (e.g., `notion-refactor`)
2. Create `~/Downloads/{YYYYMMDDHHmmss}-notion-{filename}.md`
3. Use same formatting as would be posted to Notion
4. Show user: "⚠️ Notion MCP failed after 3 retries - saved to ~/Downloads/{filename} for manual paste"
5. Include full structured content ready to copy

**Error Types Triggering Fallback**:
- Timeout (no response)
- 404 (database not found)
- 400 (invalid properties)
- Rate limit (429)
- Any non-2xx response
