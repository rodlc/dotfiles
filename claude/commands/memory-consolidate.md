---
description: Run memory consolidation and health check
---

Audit and consolidate MCP Memory database.

## Actions

1. **Health check** — `check_database_health`
2. **Duplicates cleanup** — `cleanup_duplicates`
3. **Quality analysis** — `analyze_quality_distribution`
4. **Consolidation** — `trigger_consolidation` (weekly by default)

## Options

- `/consolidate-memory` — Full audit + weekly consolidation
- `/consolidate-memory daily` — Quick consolidation
- `/consolidate-memory monthly` — Deep consolidation

## Output format

## Memory Audit

**Health:** ✅ healthy | X memories | X.X MB
**Duplicates:** X removed
**Quality:** avg X.X | high X% | low X%
**Consolidation:** [horizon] triggered

Next scheduled: [date from scheduler_status]
