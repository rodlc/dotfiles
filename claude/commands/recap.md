---
description: Update plan with session progress and exit plan mode
argument-hint: ""
---

<recap-command>

**Purpose:** Finalize plan with session results and propose approval.

**Next step:** After approval (Shift+Tab), use `/wrap` to save to Notion/Memory and sync git.

## Detect Context
Check system-reminder for "Plan mode is active" and plan file path.

## If NOT in Plan Mode
Call EnterPlanMode directly (no parameters needed).
- If user accepts → proceed with "If IN Plan Mode" logic below
- If user declines → output brief summary of session

## If IN Plan Mode

### 1. Read current plan file
Use the path from system-reminder.

### 2. Analyze session
From conversation history, extract:
- Tasks completed (✓)
- Current blockers (⚠)
- Remaining work (►)
- Key decisions made

### 3. Update plan file
Add/update sections:

```
## Résultat
**Status: [En cours | Complété ✓ | Bloqué ⚠]**
[Brief description]

## Progression
✓ [completed items]
⚠ [blockers if any]

## Learnings (optional)
[Key insights, anti-patterns avoided, decisions rationale]

## Next Steps
► [actionable next steps, if work remains]
```

### 4. Exit Plan Mode
ALWAYS call ExitPlanMode after updating plan file.
- This triggers the confirmation prompt for user review
- User can then approve (Shift+Tab) to transition to edit mode
- In edit mode, user can run `/wrap` for Notion/Memory/Git sync

## Formatting
Use CLAUDE.md conventions (box-drawing, status icons).

## Critical
- ALWAYS update plan file BEFORE calling ExitPlanMode
- ALWAYS call ExitPlanMode after updating the plan, regardless of completion status
- DO NOT perform Notion/Memory/Git operations here (reserved for `/wrap` in edit mode)
- Execute silently: NO intermediate commentary, just actions and final output

## Typical workflow

```
/recap          → update plan, propose approbation
[Shift+Tab]     → approve, passe en edit mode
/wrap           → notion + memorize + git sync
```

</recap-command>
