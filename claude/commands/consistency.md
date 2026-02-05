---
description: Validate Memory ↔ Plan ↔ Notion consistency (from current context)
---

<consistency-command>

## Input
No argument required. Analyzes all data visible in current LLM context window.

## Prerequisites
This skill analyzes data **already present in the LLM context window**.
It does NOT perform new searches — it uses what was loaded during the session
(via `/context`, file reads, MCP calls, etc.).

If no relevant data is visible in context: "⚠ No data in context. Run /context {subject} first to load data."

## Roles

```
┌─────────────────────────────────────────────────────────────────────┐
│ Memory  = Index/backup (stub)          → Persistent reference       │
│ Plan    = Local technical reference    → Session source of truth    │
│ Notion  = Personal reference           → High-level view, tracking  │
└─────────────────────────────────────────────────────────────────────┘
```

## Workflow

### 1. Identify elements in LLM context

Scan the current context window to extract:
- **Plans**: ~/.claude/plans/*.md files read or mentioned
- **Memory**: visible MCP memory results (stubs, retrieve, search)
- **Notion**: pages/tasks returned by Notion MCP calls

Valid sources: `/context`, `Read`, `mcp__memory-service__*`, `mcp__notion-*__*`

**Do NOT re-run searches.** Use only what is already visible.

### 2. Build link index

For each element present in context:
- Plans → extract `notion:posted:<page_id>` if present
- Notion → note the page_id
- Memory stubs → extract `Plan:` and `Notion:` references

### 3. Evaluate consistency

| Situation          | Status | Suggested action                       |
|--------------------|--------|----------------------------------------|
| Complete           | ✓      | —                                      |
| Memory + Plan      | ✓      | Normal (WIP, not posted yet)           |
| Plan + Notion      | ⚠      | `/memorize` missing                    |
| Plan only          | ⚠      | `/memorize` to create stub             |
| Notion only        | ⚠      | Create Plan + `/memorize`              |
| Memory + Notion    | ⚠      | Plan missing (unusual direct link)     |
| Memory only        | ⚠      | Check if plan exists, else orphan      |

### 3b. Detect non-stub memories (cleanup candidates)

Identify memories that contain session content but are NOT stubs:
- **Session summaries** without `session-stub` tag
- **Full session content** (long text, no Plan/Notion refs)
- **Duplicate content** covered by existing stubs

These bloat the memory index and slow down decay.

**Detection criteria:**
- Tags include `session` but NOT `session-stub`
- Content > 500 chars without `Plan:` or `Notion:` reference
- Title contains "Session", "Summary" without stub structure

### 4. Output

```
🔗 Consistency Check
────────────────────────────────────────────────────────────────
✓ {N} complete triangles (Memory + Plan + Notion)
✓ {N} valid WIP (Memory + Plan, not posted yet)

⚠ Missing Memory stub:
  - {Notion title} ({page_id}) → /memorize
  - {Plan filename} → /memorize

⚠ Missing Notion post:
  - {Plan filename} → /recap

🗑 Non-stub memories (cleanup candidates):
  - {Memory title} ({hash}) → Convert to stub + delete original

► Suggested actions:
  /memorize   (index untracked Notion/Plans)
  /recap      (post unposted Plans to Notion)
  /memory-clean (after converting non-stubs)
```

**Action mapping:**
| Gap detected | Fix |
|--------------|-----|
| Notion without stub | `/memorize` |
| Plan without stub | `/memorize` |
| Plan without Notion | `/recap` |
| Notion without Plan | Legacy task, ignore or create plan manually |
| Non-stub memory (full content) | `/memorize` (create stub) + `delete_memory` |

**Key principle**: Memory = INDEX of everything (past + present).
Flag ALL gaps so they can be progressively backfilled.

**Cleanup principle**: Non-stub memories bloat the index.
Convert to stub first, then delete original to avoid data loss.

Display only:
- Count of ✓ (complete + valid WIP)
- Detail of ⚠ grouped by action type
- Suggested actions at the end

## Critical
- **NO new searches** — analyze only the LLM context window
- Works with any source (not just `/context`)
- Synthesize, don't dump

</consistency-command>
