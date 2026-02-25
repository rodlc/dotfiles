---
name: posthog
description: >
  PostHog hub for Submagic (project 48392). Covers A/B experiments
  (setup, launch, validate, analyze), insight creation, HogQL queries,
  and PostHog AI consultation. Use when working with PostHog experiments,
  feature flags, analytics insights, funnels, or data queries.
argument-hint: "[experiment|insight|query|ask] [details]"
allowed-tools: "mcp__posthog__* WebFetch(https://posthog.com/*) WebFetch(https://us.posthog.com/*) WebFetch(https://eu.posthog.com/*)"
---

# PostHog Hub — Submagic

## Context

```
Project ID       : 48392 (EU instance)
Growthboard      : dashboard 477928
A/B Test Board   : dashboard 519019
Stripeboard      : dashboard 518344
Trigger Board    : dashboard 528615
Adopt Actions    : dashboard 539127
MCP tools        : mcp__posthog__* (when connected)
Stack            : React/Next.js, Remotion, PostHog JS SDK
Billing mode     : identified_only (~USD 0.00005/event)
```

### Submagic Quick Ref
- 3M+ users, 3,500-4,000 signups/day, ~3% conversion
- Pricing: Starter 12EUR, Pro 23EUR, Business 41EUR, Magic Clips +12EUR
- AI users convert 70% better (20.4% vs 12.0%)

────────────────────────────────────────

## PostHog AI (`/posthog ask <question>`)

Consult PostHog AI (Max) BEFORE any non-trivial action:
1. Use MCP tool `mcp__posthog__*` if available
2. Fallback: WebFetch `https://posthog.com/docs/...` relevant page
3. ⚠ Cross-check Max answers with reference.md — Max ignores our edge cases (Webflow redirects, Stripe DW dedup, cross-domain bridging)

**Good questions for Max:**
- Setup: "How to configure redirect experiment with feature flags?"
- HogQL: "Does HogQL support window functions?" (answer: YES)
- Billing: "What counts as a billable event for feature flags?"
- SDK: "How to use posthog-js with Next.js App Router?"

────────────────────────────────────────

## Domain Routing

### `/posthog experiment [phase|details]`
A/B test lifecycle — setup, launch, validate, analyze, monitor.

**MANDATORY - READ ENTIRE FILE**: Read [`experiment.md`](experiment.md) (~165 lines) completely from start to finish. **NEVER set any range limits when reading this file.**

### `/posthog insight [type|details]`
Create and configure PostHog insights — funnels, trends, retention, HogQL.

**MANDATORY - READ ENTIRE FILE**: Read [`insights.md`](insights.md) (~115 lines) completely from start to finish. **NEVER set any range limits when reading this file.**

### `/posthog query [pattern|details]`
HogQL templates — validated queries ready to adapt.

**MANDATORY - READ ENTIRE FILE**: Read [`queries.md`](queries.md) (~280 lines) completely from start to finish. **NEVER set any range limits when reading this file.**

### `/posthog ask [question]`
Consult PostHog AI (Max) — see "PostHog AI" section above. No sub-file needed.

### `/posthog` (no argument)
Display this routing table. Ask user which domain they need.

────────────────────────────────────────

## Reference

Cross-cutting pitfalls, conventions, and patterns shared across all domains.

**MANDATORY - READ ENTIRE FILE**: Read [`reference.md`](reference.md) (~180 lines) when encountering pitfalls, edge cases, or unfamiliar PostHog behavior. **NEVER set any range limits when reading this file.**

────────────────────────────────────────

## Active Experiments

| Experiment | Flag | Split | Dashboard | Status |
|------------|------|-------|-----------|--------|
| homepage-redesign | `homepage-redesign` | 50/50 | 519019 | Analysis complete |
| hard-reverse-trial | `hard-reverse-trial` | 80/20 | 519019 | Monitoring (launched 2026-02-16) |

## Key Insight IDs (dashboard 519019)

### homepage-redesign
| Metric | Short ID |
|--------|----------|
| Signup + P-value | qSgJRy34 |
| videoUploadInitiated + P-value | ouRagmLs |
| planPurchased + P-value | q4f9IE2P |
| Stripe (cross-domain z-test) | 5HvdLc5q |
| Cross-domain Stripe (legacy) | V6FhR2DE |

### hard-reverse-trial
| Metric | Short ID |
|--------|----------|
| Experiment Summary (DW) | 2zr7IsOF |
| Experiment Summary (Invoices) | Jt8oqClh |
| Signup→Upload→Export | 1ZDLWDdG |
| Subs by variant × status | Mxwhs3PE |
| MRR by variant (DW) | Q6mikbMF |
| MRR by variant (Invoices) | kYnJZyiE |
| Subs & MRR by tier (DW) | uL9ZuWUl |
| Subs & MRR by tier (Invoices) | DCjQkRzh |
| Cancel Reasons by variant | JPKoqtWe |
| Z-test significance | TCz9t5UZ |

### Stripe MRR
| Metric | Short ID |
|--------|----------|
| New MRR | Ia4W3q8s |
| Expansion cohort | TYBWNoFQ |
| New Subs cohort | ICTMvQHx |

## Payment Trigger Dashboard (528615) — v2.3

14 tiles, all dimensions covered. `remove_watermark` = $32K/mo, 73% new sub revenue.

| ID | Name | Category |
|----|------|----------|
| `rVG48Jgd` | Feature Leaderboard (3d attribution) | Attribution |
| `mpHlFuHx` | Adopt Triggers by Plan | Attribution |
| `6kcaoCWr` | Adore Triggers by Plan | Attribution |
| `V4Hl37wQ` | Modal Fatigue Check | Attribution |
| `6DapjpUr` | Time-to-Activate (30d) | Timing |
| `cAFV1Nv8` | Time-to-Adopt (30d) | Timing |
| `6WAq18gA` | Time-to-Adore (180d) | Timing |
| `9h9hvvBo` | Last Event Before Adopt (by plan) | Last Event |
| `cKUichM8` | Last Event Before Adore (by plan) | Last Event |
| `TE8RCYBN` | Adopt Context — Plan × Page × Feature (3d) | Context |
| `dRR5RA7E` | Adore Context — Plan × Page × Feature (3d) | Context |
| `dBtSgn7L` | Activate & Adopt Rate by BCG Quadrant | BCG |
| `VL8QTSJ0` | BCG Country Matrix | BCG |
| `a25LC5Ly` | BCG Quadrant Summary | BCG |

## Insight Description Conventions

Format: [What it measures]. [Key constraint]. [Scope].

Rules:
- No internal codes (B1–B8) — use plain English
- Constraints: explain filtering logic in plain English (temporal, cohort, exclusions)
- Keep under 120 chars when possible

────────────────────────────────────────

## Adopt Actions Dashboard (539127)

8 tiles: feature→conversion analysis. First-time buyers, impact_mrr in $.

| # | ID | Name |
|---|-----|------|
| 1 | `ViFLZSR9` | AI Usage × Plan (Correlation) |
| 2 | `QWHVmMAl` | AI Usage × Plan (Causation) |
| 3 | `EZ2rnKQy` | Features × Plan (Correlation) |
| 4 | `t2nlQt2k` | Features × Plan (Causation) |
| 5 | `aOPM5WOI` | Engagement Tier × Plan (Correlation) |
| 6 | `3oPTVkfU` | Engagement Tier × Plan (Causation) |
| 7 | `IyFDqojj` | Clusters × Plan (Correlation) |
| 8 | `fXYeTt5O` | Clusters × Plan (Causation) |
