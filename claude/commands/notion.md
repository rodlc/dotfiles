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

- **Task**: Generate from conversation (use `$ARGUMENTS` as override if provided)
- **Priority**: Quick (~5min) | D2 (~30min) | W5 (~2h) | Scheduled | Reminder | Errand
- **Do date**: Today
- **Done**: Yes if complete
- **Project/Area**: Link if found, empty otherwise

## Content Templates

**Detect type from context, adapt structure:**

### 🔧 Setup/Config (Technical sessions)
```markdown
## Context
[Problem, trigger, initial state]

## Decisions
- [x] Action completed
- [x] Config changed

## Summary
**Result:**
- Key outcomes
**Modified files:**
- path/to/file:lines (code refs)
**Metrics:** [if applicable]

## Sources
- [Link](url)
```

### 🔍 Research (Comparisons, financial analysis)
```markdown
## 📁 TITLE (CAPS + Context)

### Audit / Hypotheses
[Validation tables]

### Detailed Calculations
[Financial tables, formulas if needed]

### Blind Spots / Risks
[Risk assessment table]

### Final Verdict
[Comparison table + Winner]

### Roadmap
- [ ] Action checkboxes

> Impactful closing quote
```

### 🔬 Analysis (Strategic decisions)
```markdown
### Market Standard
[Benchmark tables]

### Current Position
[Strengths/weaknesses table]

### Tactics / Options
[Options with inline quotes]

### Final Matrix
[Comparison table + Ranking emojis 🥇🥈🥉]

**Summary in one sentence**
```

### 💻 Learning / Simple notes
```markdown
[Bullet lists, definitions, no complex structure]
```

**Default to 🔧 Setup/Config if type unclear**

## Rules

- Concise: actionable info only
- Code refs: file:line format
- Resources: suggest only (user handles BASB merge)
- On API error: show summary for manual copy

## Style Guide (from user patterns)

**Title emojis:**
- 🔧 = Setup, Config, Tools
- 🔍 = Research, Exploration
- 🔬 = Analysis, Strategy, Experiments
- 💻 = Learning, Code, Technical notes
- 🔖 = Tasks, Checklists, User stories
- 🌐 = Online research
- 📞 = Phone call
- 🤝 = In-person meeting
- 📧 = Email/Message
- 🧮 = Data analysis

**When to use tables:**
- Comparing options (≥2 alternatives)
- Structured data (budgets, timelines, specs)
- Risk assessment
- Benchmarks

**Closing:**
- Research/Analysis: Add impactful quote or one-sentence summary
- Technical: Keep dry, focus on next actions

## Technical Notes

**Property formats** (critical for API success):
- Area/Project: Single URL string, NOT array
  - ✅ `"Area": "https://www.notion.so/6d9b458c..."`
  - ❌ `"Area": ["https://www.notion.so/6d9b458c..."]`
- Date properties: Use `date:PropertyName:start`, `date:PropertyName:is_datetime`
- Done: Use `"__YES__"` or `"__NO__"`

**Search strategy**:
1. Identify main topic keyword (e.g., "Code", "Finance")
2. Search existing Areas/Projects: `notion-search` with keyword
3. Match by relevance in search results
4. Use URL directly in properties (no brackets)

**Common errors**:
- "Invalid input" → Check property types (string vs array)
- Area not found → Leave empty, user will link manually
- Duplicate pages → Search first to avoid recreation
