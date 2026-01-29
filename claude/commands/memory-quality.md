---
description: Audit qualité
---

Analyse la distribution de qualité des mémoires et propose des actions.

## Workflow

1. `analyze_quality_distribution` - Vue d'ensemble de la qualité
2. Afficher top 10 high-quality memories
3. Afficher bottom 10 low-quality memories
4. Proposer actions:
   - Rate high-value memories (si pas déjà fait)
   - Delete/improve low-quality (<0.3)
   - Review medium-quality (0.3-0.5)

## Output Format

```
╔════════════════════════════════════════════════════════════════╗
║  MEMORY QUALITY AUDIT                                          ║
╠════════════════════════════════════════════════════════════════╣
║  Total memories:     XXX                                       ║
║  Average quality:    X.XX                                      ║
║  High (≥0.7):        XX (XX%)                                  ║
║  Medium (0.5-0.7):   XX (XX%)                                  ║
║  Low (<0.5):         XX (XX%)                                  ║
╚════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│  TOP 10 HIGH-QUALITY MEMORIES                                   │
├─────────────────────────────────────────────────────────────────┤
│  1. [0.95] Convention: Rails naming...                          │
│  2. [0.92] Identity: Full contact...                            │
│  ...                                                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  BOTTOM 10 LOW-QUALITY MEMORIES                                 │
├─────────────────────────────────────────────────────────────────┤
│  1. [0.15] Temporary note...          → DELETE                  │
│  2. [0.22] Vague reference...         → REVIEW                  │
│  ...                                                            │
└─────────────────────────────────────────────────────────────────┘

► Recommended actions:
  • Rate 5 high-quality memories (currently unrated)
  • Delete 3 low-quality (<0.3) memories
  • Review 12 medium-quality memories for improvement
```

## Notes

- Quality system must be enabled (MCP_QUALITY_SYSTEM_ENABLED=true)
- If quality system disabled, will show message and instructions to enable
- Can be run monthly as part of maintenance workflow
