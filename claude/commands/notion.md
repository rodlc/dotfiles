---
description: Save session summary to Notion Tasks database
argument-hint: "[priority] [title]"
---

Save a structured summary of this conversation to Notion Tasks.

## Workflow

1. **Analyze**: Extract context, decisions, outcomes from conversation
2. **Infer Area**: Determine from discussion topic, search if needed
3. **Find Project**: Search related Project in Area (skip if costly)
4. **Create Task**: Use Tasks data source from CLAUDE.md

## Properties

- **Task**: Short title in EN, use | or / for sub-elements (override with `$ARGUMENTS`)
- **Priority**: Quick (~5min) | D2 (~30min) | W5 (~2h) | Scheduled | Reminder | Errand
- **Do date**: Today
- **Done**: Yes if complete
- **Project/Area**: Link if found, empty otherwise

**Examples:**
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

## Style Guide

**Emojis:** 🔧 Setup | 🔍 Research | 🔬 Analysis | 💻 Learning | 🔖 Tasks | 🧮 Data | (+ others as needed)

**Language:**
- Titles: EN
- Content: Match discussion language

**Tables:** Use for comparisons (≥2 options), structured data, risks, benchmarks

**Closing:** Research/Analysis = quote/summary | Technical = next actions

**Concise:** Actionable info only, code refs as file:line

**Plan reference:** If a plan file exists in `~/.claude/plans/` modified within the last hour, add in Sources section:
- `📋 Plan: ~/.claude/plans/{filename}.md`

## Technical Notes

**Property formats** (critical for API):
- Area/Project: Single URL string, NOT array
  - ✅ `"Area": "https://www.notion.so/6d9b458c..."`
  - ❌ `"Area": ["https://www.notion.so/6d9b458c..."]`
- Date: Use `date:PropertyName:start`, `date:PropertyName:is_datetime`
- Done: Use `"__YES__"` or `"__NO__"`

**Search strategy:**
1. Identify keyword (e.g., "Code", "Finance")
2. Search Areas/Projects with `notion-search`
3. Use URL directly in properties (no brackets)

**Common errors:**
- "Invalid input" → Check string vs array
- Area not found → Leave empty, user links manually
- Duplicates → Search first

**On API error:** Show summary for manual copy

**Timeout fallback:**
If ANY Notion MCP call fails (timeout, 404, rate limit):
1. Infer concise filename from conversation topic (e.g., `wrap-skill-setup`)
2. Create `~/Downloads/{YYYYMMDDHHmmss}-notion-{inferred-filename}.md`
3. Use same formatting as would be posted to Notion
4. Show user: "⚠️ Notion MCP failed - saved to ~/Downloads/{filename} for manual paste"
5. Include full structured content ready to copy

Example: `~/Downloads/20260104233045-notion-wrap-skill-setup.md`

**Error types triggering fallback:**
- Timeout (no response)
- 404 (database not found)
- 400 (invalid properties)
- Rate limit (429)
- Any non-2xx response
