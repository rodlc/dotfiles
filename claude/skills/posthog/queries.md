# HogQL Query Templates

Validated queries for Submagic PostHog (project 48392). Copy and adapt.

════════════════════════════════════════

## Reusable Patterns

### Exposure Dedup (ROW_NUMBER)
```sql
-- First exposure per person for a given flag
-- ⚠ Use toString(properties['$feature/...']) — backtick syntax silently returns NULL via MCP
SELECT variant, person_id FROM (
  SELECT
    toString(properties['$feature/flag-name']) AS variant,
    person_id,
    ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY timestamp ASC) AS rn
  FROM events
  WHERE event = '$feature_flag_called'
    AND toString(properties['$feature_flag']) = 'flag-name'
    AND toString(properties['$feature/flag-name']) IN ('control', 'variant')
    AND timestamp >= '2026-02-XX'  -- exact launch time
) WHERE rn = 1
```

### Optional Filters (apply when needed)
```sql
-- Localhost exclusion (works in saved insights, may fail via MCP tool)
AND NOT match(toString(properties.$host), '^(localhost|127\\.0\\.0\\.1)($|:)')
-- UUID null check
AND person_id != '00000000-0000-0000-0000-000000000000'
```
⚠ These filters are optional — existing insights (2zr7IsOF, 1ZDLWDdG) work without them.

### Cross-domain Bridge ($device_id → email → Stripe)
```sql
-- Step 1: Map device_id to email
WITH device_emails AS (
  SELECT DISTINCT
    properties.$device_id AS device_id,
    person.properties.email AS email
  FROM events
  WHERE event IN ('signup', '$identify')
    AND person.properties.email IS NOT NULL
    AND person.properties.email != ''
)
-- Step 2: Join exposures to Stripe via email
SELECT
  e.variant,
  s.status,
  count(DISTINCT s.id) AS subs
FROM exposures e
JOIN device_emails de ON de.device_id = e.device_id
JOIN stripe.subscription s ON s.customer_email = de.email
GROUP BY e.variant, s.status
```
Template insight: **V6FhR2DE**

### flat+arrayJoin Pattern (avoids CTE timeout)
```sql
-- CTE = macro in HogQL → N× evaluation → timeout
-- Instead: flatten per-person, then arrayJoin + filter

-- Step 1: Aggregate events per person per variant
SELECT
  variant,
  event_name,
  count(DISTINCT person_id) AS unique_persons
FROM (
  SELECT
    variant,
    person_id,
    arrayJoin(events_array) AS event_name
  FROM (
    SELECT
      toString(properties['$feature/flag-name']) AS variant,
      person_id,
      groupArray(event) AS events_array
    FROM events
    WHERE event IN ('signup', 'videoUploadInitiated', 'planPurchased')
      AND timestamp >= '2026-XX-XX'
    GROUP BY variant, person_id  -- ← per-person aggregation
  )
)
GROUP BY variant, event_name
ORDER BY variant, event_name
```

### argMax Stripe Dedup (multi-subscription users)
```sql
-- When user has multiple subscriptions, get latest
SELECT
  customer_email,
  argMax(status, created_at) AS current_status,
  argMax(plan_amount, created_at) AS current_amount
FROM stripe.subscription
GROUP BY customer_email
```

════════════════════════════════════════

## Churning Classification (Stripe DW)

```sql
-- Classify subscription status including pending cancellations
multiIf(
  ss.email IS NULL, 'none',
  ss.status = 'canceled' OR ss.cancel_at_period_end = 1, 'churning',
  ss.status = 'trialing', 'trialing',
  ss.status = 'past_due', 'past_due',
  ss.status = 'active', 'clean_active',
  ss.status
) AS sub_status
```

**Invariant**: subs = trialing + past_due + churning + clean_active
Filter out: `incomplete`, `incomplete_expired`

### billing_reason for MRR Classification
```
subscription_create  → New MRR
subscription_update  → Expansion/Contraction
subscription_cycle   → Renewal
```

### Invoice Dedup
```sql
-- ~18× duplicates per invoice in Stripe DW
SELECT
  id,
  min(customer_email) AS email,
  min(total) AS total,
  min(currency) AS currency,
  min(billing_reason) AS billing_reason
FROM stripe.invoice
GROUP BY id
```

### Multi-item Subscription Handling
```sql
-- plan=null for multi-item subs → JSON fallback
CASE
  WHEN plan_amount IS NOT NULL THEN plan_amount
  ELSE JSONExtractInt(items_data, 'data', 0, 'price', 'unit_amount')
END AS amount
```

════════════════════════════════════════

## Z-test Significance

```sql
-- Reusable z-test for A/B conversion comparison
-- Template insight: TCz9t5UZ

WITH
  control AS (
    SELECT
      count() AS n,
      count(if(converted = 1, 1, NULL)) AS x
    FROM experiment_data
    WHERE variant = 'control'
  ),
  treatment AS (
    SELECT
      count() AS n,
      count(if(converted = 1, 1, NULL)) AS x
    FROM experiment_data
    WHERE variant = 'test'
  )
SELECT
  c.x / c.n AS p_control,
  t.x / t.n AS p_treatment,
  t.x / t.n - c.x / c.n AS lift,
  -- z-score
  (t.x / t.n - c.x / c.n) /
    sqrt((c.x / c.n * (1 - c.x / c.n) / c.n) + (t.x / t.n * (1 - t.x / t.n) / t.n))
    AS z_score,
  -- p-value via erf()
  1 - erf(
    abs(t.x / t.n - c.x / c.n) /
    sqrt((c.x / c.n * (1 - c.x / c.n) / c.n) + (t.x / t.n * (1 - t.x / t.n) / t.n))
    / sqrt(2)
  ) AS p_value,
  -- significance label — guard: np≥5 required in BOTH groups (normal approximation validity)
  if(
    least(c.x, t.x) < 5,
    '⚠ np<5',
    multiIf(p_value < 0.01, '✓✓✓ p<0.01', p_value < 0.05, '✓✓ p<0.05', p_value < 0.10, '✓ p<0.10', '')
  ) AS sig
FROM control c, treatment t
```

════════════════════════════════════════

## homepage-redesign Queries (dashboard 519019)

### Signup + P-value — qSgJRy34
Same as above with z-test significance appended (see z-test template).

### videoUploadInitiated + P-value — ouRagmLs
Replace `signup` with `videoUploadInitiated` in conversion query + z-test.

### planPurchased + P-value — q4f9IE2P
Replace `signup` with `planPurchased` in conversion query + z-test.

### Stripe (cross-domain z-test) — 5HvdLc5q
Cross-domain bridge: `$device_id` → email → `stripe.customer` → `stripe.subscription`.
Z-test on clean_active subscription rate (excludes `cancel_at_period_end`).
Replaces deleted sgUqt2iZ.

### Daily Trend by Variant
```sql
SELECT
  toDate(e.timestamp) AS day,
  e.variant,
  count(DISTINCT e.person_id) AS exposures
FROM exposures e  -- use exposure CTE
GROUP BY day, e.variant
ORDER BY day, e.variant
```

════════════════════════════════════════

## hard-reverse-trial Queries (dashboard 519019)

### Experiment Summary (sub/churn z-tests) — 2zr7IsOF
Combines exposure dedup + subscription status + z-test for:
- Subscription rate (control vs treatment)
- Churn rate (control vs treatment)

### Signup→Upload→Export (z-tests) — 1ZDLWDdG
3 z-tests on funnel: signup, videoUploadInitiated, projectExported.
Uses flat+arrayJoin pattern for performance.

### Subs by Variant × Status — Mxwhs3PE
```sql
-- Breakdown: variant × sub_status (churning classification)
SELECT
  variant,
  multiIf(...) AS sub_status,  -- see churning classification
  count(DISTINCT person_id) AS users
FROM ...
GROUP BY variant, sub_status
```

### MRR by Variant (Stripe DW) — mONyHF9v
Cross-domain bridge → Stripe subscription → plan_amount aggregation.

### Subs by Variant × Tier — 1K6JNQiu
Breakdown by pricing tier (Starter/Pro/Business/Magic Clips).

### MRR by Variant × Tier — Lzm9Yz5d
Revenue breakdown by variant and pricing tier.

### Z-test Significance — TCz9t5UZ
Standalone z-test template applied to hard-reverse-trial data.

════════════════════════════════════════

## Stripe MRR Queries

### New MRR (subscription_create) — Ia4W3q8s
```sql
SELECT
  toStartOfMonth(created_at) AS month,
  sum(total) / 100 AS new_mrr
FROM (
  SELECT id, min(total) AS total, min(created_at) AS created_at
  FROM stripe.invoice
  WHERE billing_reason = 'subscription_create'
  GROUP BY id
)
GROUP BY month
ORDER BY month
```

### Expansion Candidates — TYBWNoFQ
Filter by `billing_reason = 'subscription_update'` + positive delta.

### New Subs Cohort — ICTMvQHx
Filter by `billing_reason = 'subscription_create'` grouped by week.
