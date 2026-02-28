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
- If user accepts → **IMMEDIATELY continue** with the steps below (do NOT stop after EnterPlanMode)
- If user declines → output brief summary of session

## Main Logic (execute after EnterPlanMode succeeds OR if already in Plan Mode)

### 1. Read current plan file
Use the path from system-reminder.

### 2. Analyze session
From conversation history, extract:
- Tasks completed (✓)
- Current blockers (⚠)
- Remaining work (►)
- Key decisions made

### 3. Update plan file
Read existing plan content first. PRESERVE all prior context.
Add/update the following sections (do NOT replace existing content):

```
If sections already exist → UPDATE in place (do NOT duplicate).
On successive recaps:
- Merge new ✓ items into existing Progression
- Condense resolved ✓ clusters → single summary line (e.g. "✓ Auth flow — 3 endpoints + tests")
- Update Status field, don't append a new one
- Append new ► items to Next Steps, remove completed ones

═══════════════════════
Résultat
═══════════════════════
Status: [En cours | Complété ✓ | Bloqué ⚠]
[≤ 3 lignes]

═══════════════════════
Progression
═══════════════════════
✓ [completed — condense clusters > 5]
⚠ [blockers]

──── Learnings (optional) ────
├── [insight 1]
└── [insight 2]

──── Scorecard (si actions multi-parties) ────
@Alice
  ☐ action 1
  ☑ action 2
@Bob
  ☐ action 3

═══════════════════════
Next Steps
═══════════════════════
► [actions restantes]
```

### 4. Exit Plan Mode
ALWAYS call ExitPlanMode after updating plan file.
- This triggers the confirmation prompt for user review
- User can then approve (Shift+Tab) to transition to edit mode
- In edit mode, user can run `/wrap` for Notion/Memory/Git sync

## Formatting
Follow CLAUDE.md § Formatting conventions. Recap-specific:
- Condense completed ✓ clusters → summary line as plan grows
- Preserve `# Titre` as H1 markdown (plan mode system-reminder compatibility)

Example output:
```
═══════════════════════
Résultat
═══════════════════════
Status: Complété ✓
Auth flow implémenté, 3 endpoints + tests.

═══════════════════════
Progression
═══════════════════════
✓ Auth flow — 3 endpoints + tests
✓ DB migration — users table

──── Learnings ────
├── OAuth token refresh nécessite scope offline
└── Zod validation avant MCP call

═══════════════════════
Next Steps
═══════════════════════
► Deploy staging
```

## Critical
- After EnterPlanMode succeeds, CONTINUE IMMEDIATELY with the main logic (do NOT wait for user input)
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
