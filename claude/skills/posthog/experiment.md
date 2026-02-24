# Experiment Playbook — A/B Test Lifecycle

5-phase lifecycle for Submagic A/B experiments on PostHog (project 48392).

════════════════════════════════════════

## Phase 0 : Ask PostHog AI

Before any experiment setup:
1. Describe the experiment to PostHog AI (Max)
2. Ask: setup approach, metric recommendations, sample size
3. Cross-check with our conventions below (Max ignores Webflow/Stripe specifics)

════════════════════════════════════════

## Phase 1 : Setup

### Checklist
- [ ] Create experiment in project 48392
- [ ] Feature flag naming: `{page}-{variant-name}` (e.g. `homepage-redesign`)
- [ ] Rollout: start 90/10 (smoke test)
- [ ] Verify `person_profiles: "identified_only"` in PostHogProvider
- [ ] Webflow: redirect script in **Head Code** (shared staging/prod)
- [ ] Preserve UTM params: append `window.location.search + window.location.hash`
- [ ] Configure **Authorized URLs** for Toolbar

### Webflow Redirect Pattern
```javascript
// Head Code — redirect to variant page
!function(){
  try {
    const flag = posthog.getFeatureFlag('flag-name');
    if (flag === 'variant') {
      const params = window.location.search + window.location.hash;
      window.location.replace('/variant-page' + params);
    }
  } catch(e) { /* fallback = control (safe) */ }
}();
```

### Key Decisions
- `identified_only` billing → pre-signup pageviews NOT attributed to Person Profile
- Client-side redirect = safe fallback (PostHog down → control)
- Head code shared staging/prod → one publish affects both

════════════════════════════════════════

## Phase 2 : Launch

### Checklist
- [ ] Verify exposure events in **Live Events** tab
- [ ] ⚠ Flag scope: `www.submagic.co` only (NOT `app.submagic.co`)
- [ ] ⚠ Direct `/signup` access = missed exposure (bypass detection)
- [ ] Smoke test 24h → expect ≥1 signup per variant
- [ ] If OK → switch to 50/50 (or target split)

### Bypass Detection
1. Direct page access may skip flag evaluation
2. Hardcoded boolean overrides bypass flags
3. `router.push()` navigation circumvents modal flows
4. Background jobs may lack user context
5. `useServerFeatureFlag()` can evaluate without consuming result

### Flag Behavior
- Auto-activated when experiment launched via API
- Rollback: deactivate flag (`active: false`) or stop experiment

════════════════════════════════════════

## Phase 3 : Validate

### Checklist
- [ ] **SRM test**: chi² on variant ratios (detect sampling bias)
- [ ] Entity: `person_id` (NOT `distinct_id` — -20% accuracy)
- [ ] UUID null check: `person_id != '00000000-0000-0000-0000-000000000000'`
      (NOT `!= ''`)
- [ ] Localhost filter: `NOT match(toString(properties.$host), '^(localhost|127\\.0\\.0\\.1)($|:)')`
- [ ] Start date = exact launch time (not midnight UTC)
- [ ] Cross-check custom HogQL vs native PostHog (±1% tolerance)
- [ ] Minimum **7 days** before conclusions (novelty effect)
- [ ] **Z-test validity**: np ≥ 5 in both groups (if not met → sig = `n.p`, wait for data)

### SRM Quick Test
```
Expected ratio: 50/50 (or 80/20, 90/10)
Chi² = Σ (observed - expected)² / expected
p < 0.01 → SRM detected → investigate
```

### Entity Selection
```
person_id  : all exposed users, cross-session (~7 $multiple users)
email      : for Stripe JOIN, -17% vs person_id count
native     : Bayesian, uses internal dedup
```

════════════════════════════════════════

## Phase 4 : Analyze

### Checklist
- [ ] Use **1-step funnels** (not multi-step, not $pageview)
- [ ] Exposure via feature flag = entry point (no $pageview step needed)
- [ ] 1 primary metric + 1-2 secondary metrics
- [ ] **Bonferroni correction** if >2 metrics tested
- [ ] Cross-domain: `$device_id → email → Stripe`
- [ ] ⚠ If native broken → custom HogQL with `person_id`
- [ ] Revenue: Baremetrics = MRR source of truth, PostHog = behavioral

### Metric Selection

| Stage    | Emoji | KPI     | Event / Metric        |
|----------|-------|---------|-----------------------|
| Acquire  | 👉    | Signup  | signup                |
| Activate | 🙌    | Export  | projectExported       |
| Adopt    | 🤝    | Pay     | planPurchased         |
| Renew    | ✋    | Renew   | subscription_cycle (Stripe) |
| Adore    | 🫶    | Upgrade | plan_upgrade (Stripe) |
| Refer    | 👏    | Refer?  | TBD                   |

```
Primary   : pick the stage matching experiment Goal tag
Secondary : adjacent stages (e.g. Adopt goal → also track Activate + Adore)
Avoid     : $pageview (inflated), $autocapture (unreliable)
```

### Cross-domain Bridge
```
www.submagic.co → person_id changes at app.submagic.co
Bridge path: $device_id → signup/$identify → email → Stripe customer
Template insight: V6FhR2DE
```

### When Native Is Broken
PostHog native experiment results can fail:
- validation_failures, step_counts=0
- Wrong entity type applied
→ Build custom HogQL insights (see queries.md)

════════════════════════════════════════

## Phase 5 : Monitor

Post-launch monitoring for longer experiments (e.g. hard-reverse-trial).

### Checklist
- [ ] Define **maturation window** (e.g. 3-day rolling, applied to BOTH control AND treatment)
- [ ] Build **power analysis** table: MDE by day

### Z-test Guard Pattern
```sql
-- sig column in z-test SELECT:
if(least(c.x, t.x) < 5, 'n.p',
  multiIf(p < 0.01, '***', p < 0.05, '**', p < 0.10, '*', 'n.s'))
-- n.p → insufficient data — do NOT report as significant
-- Wait: for p_baseline ~1%, need n≥500 per group before validity
```

### Power Analysis Table (example values — replace with actuals)
```
| Day | n_control | n_treatment | MDE    | Min detectable |
|-----|-----------|-------------|--------|----------------|
| 3   | 500       | 500         | 8.2%   | Large effects   |
| 7   | 1200      | 1200        | 5.3%   | Medium effects  |
| 14  | 2500      | 2500        | 3.7%   | Target MDE      |
```
MDE typical: ~5% for signup conversion experiments.

### Decision Framework
```
churn_% → net_retention → verdict
  > X%      < Y%           STOP (revert to control)
  < X%      > Y%           GO (ship variant)
  ~X%       ~Y%            EXTEND (need more data)
```

### Split Decisions
- Stay 80/20: when risk is high, want early signal with low exposure
- Switch 50/50: when smoke test passes, need statistical power faster
- Criteria: SRM clean, no bypass issues, ≥1 conversion per variant

### Architecture Pattern
- Use `flat+arrayJoin` (1× evaluation) instead of CTE chains (N× eval = timeout)
- Dedup exposures: `ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY timestamp ASC)`
- See queries.md for validated templates
