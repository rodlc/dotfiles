---
runMode: always
invokedByUser: true
location: user
---

# Memory Audit - Maintenance Mensuelle

Audit complet mensuel de MCP Memory avec rapport détaillé.

## Usage

```
/memory-audit [report_path]
```

**Paramètres:**
- `report_path` (optionnel): Chemin de sauvegarde du rapport. Défaut: ~/Downloads/memory-audit-YYYYMMDD.md

## Workflow

1. **Database Health Check**
   - `check_database_health` → baseline metrics
   - Memory count, size, embedding model, avg query time

2. **Quality Distribution**
   - `analyze_quality_distribution` → identify performers
   - High/medium/low breakdown
   - Average quality score

3. **Tag Analysis**
   - Query database for unique tags
   - Count memories per tag
   - Identify orphaned or redundant tags

4. **Cluster Review**
   - `search_by_tag(["cluster", "compressed"])` → review compressed clusters
   - Evaluate relevance
   - Mark candidates for deletion

5. **Timeframe Audit**
   - `recall_by_timeframe(days_old=180)` → candidates for archival
   - Cross-reference with quality scores
   - Flag low-quality + old memories

6. **Quality Rating**
   - Identify top 10 unrated high-value memories
   - Rate critical memories (identity, conventions, workflows)
   - Use `rate_memory` with rating=5

7. **Cleanup Recommendations**
   - Calculate deletions: quality < 0.3 AND age > 90d
   - Skip `critical` tagged memories
   - Propose delete_by_timeframe actions

8. **Generate Report**
   - Markdown report with:
     - Executive summary
     - Health metrics (before/after if cleanup done)
     - Quality distribution charts
     - Tag frequency analysis
     - Recommended actions
     - KPIs tracking
   - Save to report_path

## Output Format

```markdown
# MCP Memory Audit Report
Date: YYYY-MM-DD

## Executive Summary

╔════════════════════════════════════════════════════════════════╗
║  AUDIT RESULTS                                                 ║
╠════════════════════════════════════════════════════════════════╣
║  Total memories:        XXX                                    ║
║  Database size:         X.XX MB                                ║
║  Avg quality:           X.XX                                   ║
║  Avg query time:        XXXms                                  ║
║  High-quality (≥0.7):   XX (XX%)                               ║
║  Low-quality (<0.3):    XX (XX%)                               ║
╚════════════════════════════════════════════════════════════════╝

## Quality Distribution

[Chart/breakdown of quality scores]

## Tag Analysis

| Tag | Count | Category | Action |
|-----|-------|----------|--------|
| critical | XX | Retention | Keep |
| reference | XX | Retention | Keep |
| association | XX | Noise | Review |

## Recommendations

┌─────────────────────────────────────────────────────────────────┐
│  IMMEDIATE ACTIONS                                              │
├─────────────────────────────────────────────────────────────────┤
│  ► Delete XX low-quality memories (>90d, q<0.3)                 │
│  ► Rate XX unrated high-value memories                          │
│  ► Review XX cluster memories                                   │
└─────────────────────────────────────────────────────────────────┘

## KPIs

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Total memories | XXX | <800 | ✓/✗ |
| Avg query time | XXXms | <400ms | ✓/✗ |
| High-quality % | XX% | >60% | ✓/✗ |
| Low-quality % | XX% | <5% | ✓/✗ |
```

## Post-Audit Actions

After reviewing the report, user can:
1. Run `/memory-prune` with recommended parameters
2. Run `/memory-quality` to rate high-value memories
3. Run `/memory-clean` to remove duplicates
4. Enable quality system if not already (see report recommendations)

## Automation

Run monthly on 1st of month:
```bash
# Add to cron or calendar reminder
/memory-audit
```

## Notes

- Report saved to ~/Downloads/ for archival
- No destructive actions by default (audit only)
- Quality system activation recommendations included
- Can be run more frequently (weekly) during cleanup phases
