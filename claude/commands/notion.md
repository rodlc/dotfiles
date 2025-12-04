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

## Content Template

```markdown
## Context
[Initial state, what prompted this session]

## Decisions
- [x] Decision made
- [ ] Pending decision

## Summary
[Key outcomes, changes made]

## Sources
- [Source](url)
```

## Rules

- Concise: actionable info only
- Code refs: file:line format
- Resources: suggest only (user handles BASB merge)
- On API error: show summary for manual copy
