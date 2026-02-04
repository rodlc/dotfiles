---
description: Charge le contexte depuis Memory, Notion, et plans précédents
argument-hint: "<sujet>"
---

<context-command>

## Input
Argument: `$ARGUMENTS` (sujet à rechercher, ex: "ASS", "Vercors", "Klarigo")

## Workflow

### 1. MCP Memory (dual search)
Load memory tools, then run BOTH searches in parallel:

**Semantic search:**
```
mcp__memory-service__retrieve_memory
  query: $ARGUMENTS
  limit: 10
  similarity_threshold: 0.5
```

**Tag search** (if subject maps to known tag):
```
mcp__memory-service__search_by_tag
  tag: $ARGUMENTS (lowercase)
  limit: 10
```

Dedupe by content_hash, prioritize tagged results.

### 2. Notion PARA (targeted queries)
Query specific PARA databases instead of global search (avoids quotes/proverbs noise).

**Database IDs:**
```
Tasks:    68d1e0ee-a70a-4a27-b723-dde6ad636904
Projects: 00bc1b0f-ebeb-4b20-b117-029cced93032
Areas:    c0a5f573-ae66-4e41-9ead-2c9bacc7dd79
```

**Query each DB in parallel** (use title contains filter):
```
mcp__notion-rodlecoent__notion_query_database
  database_id: <DB_ID>
  filter: {"property": "title", "title": {"contains": "$ARGUMENTS"}}
  page_size: 10
  format: markdown
```

Note: Resources DB not indexed (too generic). Use global search only if PARA returns nothing.

For relevant pages with child blocks, retrieve content:
```
mcp__notion-rodlecoent__notion_retrieve_block_children
  block_id: <page_id>
  format: markdown
```

### 3. Plans (with context extraction)
```
Grep pattern: $ARGUMENTS (case-insensitive)
Path: ~/.claude/plans/*.md
Context: -C 2 (2 lines before/after)
```

For each matching file:
- Show filename + date (from frontmatter or filename)
- Extract matching lines WITH context
- Group by file

### 4. Synthesis & Contradiction Detection

**Priority hierarchy:**
1. Memory (tagged) → established facts, highest confidence
2. Memory (semantic) → related context
3. Plans → decisions, project context
4. Notion → tasks, actions taken

**Contradiction check:**
Compare dates/facts across sources. Flag with ⚠ if:
- Same event has different dates
- Status conflicts (e.g., "approved" vs "refused")
- Numbers differ significantly

**Output format:**
```
╔════════════════════════════════════════════════════════════════
║ 📋 CONTEXTE : {SUBJECT}
╚════════════════════════════════════════════════════════════════

Memory ({N} entries) ★ = tagged
────────────────────────────────────────────────────────────────
[Key facts grouped by theme]
[★ indicates tagged/curated memory]

Notion Tasks ({N} tâches)
────────────────────────────────────────────────────────────────
| Date | Tâche | Status |
[Only actual tasks, no quotes/proverbs]

Plans ({N} fichiers)
────────────────────────────────────────────────────────────────
**filename.md** (date)
> relevant excerpt with context
> ...

⚠ Contradictions (if any)
────────────────────────────────────────────────────────────────
[Source A says X, Source B says Y - verify which is current]

Timeline
────────────────────────────────────────────────────────────────
[Chronological view merging all sources]
```

### 5. Consolidation suggestion (optional)
If subject appears in 3+ memories OR spans 3+ months of activity:
```
💡 Suggestion: Ce sujet a beaucoup de contexte dispersé.
   Consolider en memory de référence ? (tag: reference, {subject})
```

## Error handling
- No results: "Aucun contexte trouvé pour '{subject}'"
- Partial results: Show available, note missing sources
- Tool failure: Continue with remaining sources

## Critical
- ALWAYS load MCP tools via ToolSearch before using them
- Run Memory searches in PARALLEL (semantic + tag)
- Filter Notion noise (quotes, partial matches)
- Show plan excerpts WITH context, not just filenames
- Flag contradictions explicitly
- Synthesize, don't dump raw data

</context-command>
