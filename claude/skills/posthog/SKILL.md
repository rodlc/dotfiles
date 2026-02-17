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
MCP tools        : mcp__posthog__* (when connected)
Stack            : React/Next.js, Remotion, PostHog JS SDK
Billing mode     : identified_only (~$0.00005/event)
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

**MANDATORY READ: Read the file `experiment.md` in this skill directory completely. NEVER set range limits.**

### `/posthog insight [type|details]`
Create and configure PostHog insights — funnels, trends, retention, HogQL.

**MANDATORY READ: Read the file `insights.md` in this skill directory completely. NEVER set range limits.**

### `/posthog query [pattern|details]`
HogQL templates — validated queries ready to adapt.

**MANDATORY READ: Read the file `queries.md` in this skill directory completely. NEVER set range limits.**

### `/posthog` (no argument)
Display this routing table. Ask user which domain they need.

────────────────────────────────────────

## Reference

Cross-cutting pitfalls, conventions, and patterns shared across all domains.

**MANDATORY READ: Read the file `reference.md` in this skill directory when encountering pitfalls, edge cases, or unfamiliar PostHog behavior. Read completely. NEVER set range limits.**

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
| Conversion by variant | sgUqt2iZ |
| Signup + P-value | qSgJRy34 |
| videoUploadInitiated + P-value | ouRagmLs |
| planPurchased + P-value | q4f9IE2P |
| Cross-domain Stripe | V6FhR2DE |

### hard-reverse-trial
| Metric | Short ID |
|--------|----------|
| Sub/churn z-tests | 2zr7IsOF |
| Signup→Upload→Export | 1ZDLWDdG |
| Subs by variant × status | Mxwhs3PE |
| MRR by variant (Stripe) | mONyHF9v |
| Subs by variant × tier | 1K6JNQiu |
| MRR by variant × tier | Lzm9Yz5d |
| Z-test significance | TCz9t5UZ |

### Stripe MRR
| Metric | Short ID |
|--------|----------|
| New MRR | Ia4W3q8s |
| Expansion cohort | TYBWNoFQ |
| New Subs cohort | ICTMvQHx |
