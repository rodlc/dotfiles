---
description: Save session summary to Notion Tasks database
argument-hint: "[priority] [title]"
---

Save structured summaries to Notion Tasks using plan-first workflow.

## Workflow

1. **List Recent Plans**: Find all plans modified < 5h in `~/.claude/plans/`
2. **Update Plan**: Finalize plan with session changes (Actions, Résultat, Learnings)
3. **Local Export**: Save to `~/Downloads/{YYYYMMDD}-notion-{title-slug}.md`
   - Extract title from `# Title` line in plan
   - Slugify: lowercase, spaces→hyphens, remove special chars
   - Example: `# /notion + /wrap Improvements` → `notion-wrap-improvements`
   - Full formatted content ready for manual paste
4. **Create Notion Shell**: Create task with properties only (NO content blocks)
   - Title, Priority, Do date, Done, Area/Project
5. **Update Marker**: Append `<!-- notion:posted:{page_id}:mtime:{timestamp} -->` to plan
6. **Output**: Show paths to both local file and Notion task URL

**Principles**:
- Plan = source of truth (local file in Downloads)
- Notion = metadata shell only (no content)
- Manual copy-paste workflow (reliable, no API limits)

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

## Content Strategy

**Principe** : Le plan session (`~/.claude/plans/*.md`) EST le contenu Notion.

**Options** (par ordre de préférence) :
1. **Bloc code Notion** : Coller le plan en bloc code "Plain text" directement dans la tâche
   - ✅ Box-drawing s'affiche bien en monospace
   - ✅ Pas de fichier intermédiaire
   - ✅ Single source of truth
2. **Copie Downloads** : `cp ~/.claude/plans/{plan}.md ~/Downloads/{YYYYMMDD}-notion-{slug}.md`
   - Fallback si Notion API indispo

**Ne PAS reformater** le plan - le format box-drawing est le format final.

## Marker System

**Format**: `<!-- notion:posted:{page_id}:mtime:{unix_timestamp} -->`

**Location**: End of plan file (after content)

**Behavior**:

| Situation | Action | API Calls |
|-----------|--------|-----------|
| No marker | Export local + create shell | 1 |
| Marker + plan modified | Export local + update shell | 1 |
| Marker + plan unchanged | Skip (idempotent) | 0 |

**No content sync** - shell properties only (title, priority, date, done)

## Error Handling

**Single API call** (create/update task):
- Success → Show Notion URL + local path
- Failure → Warn but local file always saved

**No retry needed** - no content sync = minimal API surface

## Style Guide

**Emojis**: 🔧 Setup | 🔍 Research | 🔬 Analysis | 💻 Learning | 🔖 Tasks | 🧮 Data

**Language**:
- Titles: EN
- Content: Match discussion language

**Tables**: Use for comparisons (≥2 options), structured data, risks, benchmarks

**Closing**: Research/Analysis = quote/summary | Technical = next actions

**Concise**: Actionable info only, code refs as file:line

## Mode Audit

**Trigger** : `/notion audit` ou `/notion audit {date}`

**Workflow** :
1. Query Notion Tasks avec Do date = {date} (défaut: aujourd'hui)
2. Lister fichiers Downloads `{YYYYMMDD}-notion-*.md`
3. Comparer et proposer factorisation :
   - Identifier thèmes communs (préfixe slug)
   - Proposer regroupements (ex: 3 notes MCP → 1 tâche "MCP | Session {date}")
   - Afficher mapping avant/après
4. Sur confirmation :
   - Renommer tâches Notion selon mapping
   - Optionnel: fusionner fichiers Downloads similaires

**Output** :
```
📊 Audit {YYYY-MM-DD}
━━━━━━━━━━━━━━━━━━━━

Notion Tasks (Do date = {date}): 4
Downloads files ({date}): 9

📦 Regroupements proposés:
┌─────────────────────────────────┬────────────────────────────┐
│ Thème                           │ Tâches/Notes               │
├─────────────────────────────────┼────────────────────────────┤
│ 🔧 Infra Claude/MCP             │ 6 notes → 1 tâche          │
│ 🔬 Tiny House                   │ 1 note (conserver)         │
│ 🔧 Admin                        │ 2 notes → 1 tâche          │
└─────────────────────────────────┴────────────────────────────┘

Appliquer ? (confirmer pour renommer)
```

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
✅ Notion shell created: https://notion.so/...
📋 Local content: ~/Downloads/{YYYYMMDD}-notion-{slug}.md

Copy content from local file to Notion task.
```

**On Notion failure**:
```
⚠️ Notion task creation failed
📋 Local content saved: ~/Downloads/{YYYYMMDD}-notion-{slug}.md
```
