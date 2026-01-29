---
description: Cleanup temporel
---

Nettoie les mémoires anciennes avec qualité insuffisante.

## Workflow

1. `recall_by_timeframe(days_old=90)` - Mémoires >90 jours
2. Filtrer par qualité < seuil (défaut: 0.3)
3. Afficher preview des candidats
4. Demander confirmation
5. `delete_by_timeframe` si confirmé

## Parameters

```
/memory-prune [days] [quality_threshold]
```

- `days` (défaut: 90): Âge minimum en jours
- `quality_threshold` (défaut: 0.3): Seuil de qualité en-dessous duquel supprimer

## Output Format

```
╔════════════════════════════════════════════════════════════════╗
║  MEMORY PRUNING AUDIT                                          ║
╠════════════════════════════════════════════════════════════════╣
║  Criteria: >90 days old AND quality <0.3                       ║
║  Candidates: XX memories                                       ║
╚════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│  DELETION CANDIDATES                                            │
├─────────────────────────────────────────────────────────────────┤
│  1. [142d old, q=0.15] Temporary note...                        │
│  2. [98d old, q=0.22] Session context...                        │
│  3. [105d old, q=0.28] Old reference...                         │
│  ...                                                            │
└─────────────────────────────────────────────────────────────────┘

⚠️  This will permanently delete XX memories.

Proceed? (y/N)
```

## Safety

- DRY RUN by default - shows candidates without deleting
- Requires explicit confirmation
- Creates backup before deletion
- Skips memories tagged `critical` regardless of quality

## Examples

```bash
# Default: >90 days, quality <0.3
/memory-prune

# Custom: >180 days, quality <0.5
/memory-prune 180 0.5

# Aggressive: >30 days, quality <0.2
/memory-prune 30 0.2
```

## Notes

- Always preserves `critical` tagged memories
- Quality threshold should be <0.5 (medium quality)
- Run after `/memory-quality` to identify candidates
- Part of monthly maintenance workflow
