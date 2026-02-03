---
description: Finalize session plan with progress and next steps
argument-hint: ""
---

Update the current session plan with progress made and next steps.

## Workflow

1. **Identify session plan**:
   - Look for plan file path in system prompt
   - If no plan exists → create retroactive summary

2. **Analyze session**:
   - What was accomplished (Actions réalisées)
   - Current status (Résultat)
   - What remains to do (Prochaines étapes)

3. **Update plan file**:
   - Add/update "## Résultat" section
   - Add/update "## Prochaines étapes" section if incomplete

4. **Output**: Summary of changes made to plan

## Plan Sections

### Required sections after /recap:

```markdown
## Résultat

**Statut**: ✅ Terminé | ⚠️ Partiel | 🔄 En cours

{What was accomplished}

## Prochaines étapes
<!-- Only if task incomplete -->

- [ ] {Next action 1}
- [ ] {Next action 2}
```

## Retroactive Plan

If no plan exists, generate from conversation:

```markdown
# {Inferred Title}

**Date**: {YYYY-MM-DD}
**Type**: 🔧 Setup | 🔍 Research | 🔬 Analysis | 💻 Learning

---

## Contexte
{Why this session happened}

## Actions réalisées
- {Key actions from conversation}

## Résultat
{Outcome}

## Prochaines étapes
- [ ] {If incomplete}
```

## Output Format

```
📝 Plan updated: ~/.claude/plans/{plan}.md
├── Résultat: {status emoji} {brief summary}
└── Prochaines étapes: {count} items (or "None - task complete")
```
