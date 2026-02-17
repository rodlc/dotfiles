# Insight Creation Patterns

Patterns for creating and configuring PostHog insights (project 48392).
Use MCP tools `mcp__posthog__*` when available. Dashboards: Growthboard 477928, A/B 519019.

════════════════════════════════════════

## Funnel Insights

### Recommended Setup
- **Events**: use custom events (signup, videoUploadInitiated, planPurchased)
- **Avoid**: $pageview as funnel step (inflated counts), $autocapture (unreliable)
- **Entity**: person_id for cross-session accuracy
- **Conversion window**: 7 days default, adjust per use case
- **1-step funnels** for A/B tests (exposure = implicit step 0)

### Submagic Funnel Reference (fév 2026)
```
Signup → Upload : 51.5% conversion
6-step funnel, 59 trigger features tracked
Quick wins identified: upgrade modal + OAuth
```

### Common Funnel Patterns
```
Signup funnel     : signup → videoUploadInitiated → projectSaved → planPurchased
Activation funnel : signup → videoUploadInitiated (within 24h)
Revenue funnel    : signup → planPurchased (within 7d)
```

════════════════════════════════════════

## Trend Insights

### Breakdown Patterns
- By variant: `properties.$feature/flag-name` (property must exist on event)
- By device: `properties.$device_type`
- By country: `properties.$geoip_country_code`
- By date: daily/weekly aggregation

### Date Ranges
- A/B test: start = exact experiment launch time
- General: last 30d, last 90d
- ⚠ Cohorts don't support "before date" → use `timestamp < now() - interval X day`

### Formulas
- Conversion rate: `A / B * 100` (A = target event, B = exposure)
- Use HogQL insight when formula builder is insufficient

════════════════════════════════════════

## Retention Insights

### Cohort Setup
- Return event: the action you want repeated (e.g. videoUploadInitiated)
- Cohort period: daily or weekly
- ⚠ person_id for accurate retention (not distinct_id)

════════════════════════════════════════

## HogQL Insights

### When to Use HogQL Over Insight Builder
- Native experiment results broken (validation_failures, step_counts=0)
- Need z-test significance calculation
- Cross-domain queries ($device_id → Stripe)
- Complex dedup (ROW_NUMBER, argMax)
- Breakdown by multiple properties simultaneously

### Architecture: flat+arrayJoin
When query has multiple CTEs that timeout:
```sql
-- Instead of CTE chains (N× evaluation):
SELECT ... FROM (
  SELECT
    variant,
    person_id,
    groupArray(event) AS events
  FROM events
  GROUP BY variant, person_id
)
-- Use arrayJoin to flatten once, then filter
```

### Z-test Significance Template
```sql
-- erf()-based z-test (see queries.md for full template)
-- Returns p-value for conversion rate difference
-- Use for: signup, upload, purchase comparisons
```

════════════════════════════════════════

## QA Tracking

### Confirmed Bugs (fév 2026)
1. Duplicate signup events (double-fire)
2. Upload event before validation completes
3. No dedup on upgradeModal trigger
4. Inconsistent startedPayment tracking

### Event Design Best Practice
- Use `projectSaved` with `edit_counts` breakdown object
- Aggregate: `SUM(edit_counts.*) GROUP BY project_id`
- Avoids event multiplication

════════════════════════════════════════

## Dashboard Reference

| Dashboard | ID | Use |
|-----------|----|-----|
| Growthboard | 477928 | Main analytics |
| A/B Test | 519019 | Experiment insights |
| Stripeboard | 518344 | Stripe MRR & subs |
