# Reference — Pitfalls & Conventions

Cross-cutting knowledge for PostHog at Submagic. Consult when encountering edge cases.

════════════════════════════════════════

## Webflow Integration

- Head code shared staging/prod → one publish affects both environments
- Client-side redirect = safe fallback (PostHog down → control served)
- `ph-no-capture` class on DOM-heavy components (>1MB payloads)
- Preserve UTM: append `window.location.search + window.location.hash` on redirect

════════════════════════════════════════

## Feature Flags

### Behavior
- Auto-activated when experiment launched via API
- Rollback: deactivate flag (`active: false`) or stop experiment
- Flag scope matters: `www.submagic.co` ≠ `app.submagic.co`

### Silent Bypass
- `useServerFeatureFlag()` can evaluate without consuming result
- Detection: grep for calls where return value isn't assigned/used

### Bypass Detection Checklist
1. Direct page access → may skip flag evaluation
2. Hardcoded boolean overrides → bypass flags entirely
3. `router.push()` navigation → circumvents modal flows
4. Background jobs → may lack user context

### Persist Flag
- Enable "Persist flag across authentication steps" to maintain variant across login
- Fixes: ~7 `$multiple` person_id users per experiment

════════════════════════════════════════

## HogQL

### ✓ Works (confirmed fév 2026)
- Window functions: `ROW_NUMBER()`, `lagInFrame()`
- LEFT JOIN on CTEs
- `NOT IN` subqueries
- `person.properties.email` — retroactive (no $identify needed)
- `filterTestAccounts` — neutral on results and perf
- `erf()` function for z-test p-values

### ✗ Does NOT Work
- `LEFT JOIN ... IS NULL` → use `NOT IN` instead
- `sumIf()` → use `sum(if())` instead
- Cohorts with "before date" or ">X days ago" (Issue #11180)
  → Workaround: `timestamp < now() - interval X day`

### Performance
- **CTE = macro** in HogQL → N× evaluation → timeout on complex queries
- **Solution**: `flat+arrayJoin` pattern (1× evaluation)
- `argMax(col, created_at)` > LEFT JOIN for dedup multi-subscription users

### Gotchas
- `$feature/variant` breakdown only works if property exists on target event
- `sum(if())` not `sumIf()` — HogQL syntax differs from ClickHouse
- UUID null: `!= '00000000-0000-0000-0000-000000000000'` (not `!= ''`)

════════════════════════════════════════

## Stripe Data Warehouse

### Churning Classification
```sql
multiIf(
  ss.email IS NULL, 'none',
  ss.status = 'canceled' OR ss.cancel_at_period_end = 1, 'churning',
  ss.status = 'trialing', 'trialing',
  ss.status = 'past_due', 'past_due',
  ss.status = 'active', 'clean_active',
  ss.status
)
```
- `cancel_at_period_end = 1` catches ALL pending cancellations (trialing OR active)
- **Invariant**: subs = trialing + past_due + churning + clean_active
- Filter out: `incomplete`, `incomplete_expired`

### billing_reason → MRR Type
| billing_reason | MRR Type |
|----------------|----------|
| `subscription_create` | New MRR |
| `subscription_update` | Expansion/Contraction |
| `subscription_cycle` | Renewal |

### Invoice Dedup
- ~18× duplicates per invoice in Stripe DW
- Always: `GROUP BY id` + `min()` on all columns

### Multi-item Subscriptions
- `plan` = null for multi-item subs
- Fallback: `JSONExtractInt(items_data, 'data', 0, 'price', 'unit_amount')`

### Dedup Multi-subscription Users
- `argMax(col, created_at)` per customer_email
- Better than LEFT JOIN (simpler, faster)

════════════════════════════════════════

## Cross-domain Tracking

### Problem
- `person_id` changes between www.submagic.co → app.submagic.co
- Cannot directly join www events to app events by person_id

### Bridge Path
```
$device_id (www) → signup/$identify event → email → Stripe customer
```

### Implementation
1. Collect `$device_id` from www exposure events
2. Join to signup/$identify events (same device_id) to get email
3. Join email to `s3_submagic_prod.stripe_subscription.customer_email`
4. Template insight: **V6FhR2DE**

════════════════════════════════════════

## A/B Test Validation

### Entity Selection
| Entity | Use | Accuracy |
|--------|-----|----------|
| `person_id` | All exposed, cross-session | Baseline |
| `email` | Stripe JOINs | -17% vs person_id |
| Native (Bayesian) | Quick check | Internal dedup |

### Filters (always apply)
```sql
AND person_id != '00000000-0000-0000-0000-000000000000'
AND NOT match(toString(properties.$host), '^(localhost|127\\.0\\.0\\.1)($|:)')
AND timestamp >= '2026-XX-XXTXX:XX:XX'  -- exact launch time
```

### Statistical Rigor
- SRM test: chi² on variant ratios before any analysis
- Bonferroni: divide α by number of metrics if >2
- Minimum 7 days (novelty effect washout)
- Cross-check custom HogQL vs native (±1% tolerance)
- MDE typical: 5% for signup conversions

════════════════════════════════════════

## Billing

### person_profiles Impact
| Mode | Cost/event | Trade-off |
|------|-----------|-----------|
| `"always"` | ~$0.000198 | 4× more expensive |
| `"identified_only"` | ~$0.00005 | Pre-signup pageviews not attributed |

**Recommendation**: `identified_only` (current Submagic config)

### PostHog Pricing (2026)
```
Product Analytics : 1M free → $0.00005/event
Feature Flags     : 1M free → $0.0001/request
Session Replay    : 5K free → $0.005/recording
Data Warehouse    : 1M rows free → $0.000015/row
Experiments       : billed with feature flags
Surveys           : 1.5K free → $0.10/response
```

════════════════════════════════════════

## Event Design

### Best Practice
- Use `projectSaved` with `edit_counts` breakdown object
- Aggregate: `SUM(edit_counts.*) GROUP BY project_id`
- Avoids event multiplication

### ph-no-capture
- Add `className="ph-no-capture"` on complex DOM components
- Prevents >1MB payload captures
