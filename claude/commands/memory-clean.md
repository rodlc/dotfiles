---
description: Cleanup duplicates and old memories
---

Cleanup routine: duplicates, expired temps, low quality.

## Actions

1. **Duplicates** — `cleanup_duplicates`
2. **Expired temps** — `delete_by_timeframe` (>30d with tag:temporary)
3. **Low quality** — Review quality <0.3, manual delete
4. **Associations** — Prune orphaned associations

## Options

- `/memory-clean` — Full cleanup (default)
- `/memory-clean dupes` — Only duplicates
- `/memory-clean temps` — Only temporary >30d
- `/memory-clean quality` — Only low quality review

## Output

## Cleanup Report

- Duplicates removed: X
- Temporary expired: X (>30d)
- Low quality reviewed: X (kept Y, deleted Z)
- Orphaned associations: X

Database size: X.XX MB → Y.YY MB (-Z%)
