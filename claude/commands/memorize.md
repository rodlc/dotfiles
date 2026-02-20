---
description: Extract metadata to MCP Memory (stubs + conventions)
---

Create Memory entries to index sessions and capture reusable knowledge.

## Memory Types

### 1. Session Stubs (primary use)
Minimal pointers to index completed work:

```
[session-stub] {title}
Date: {date}
Plan: {plan_path}
Notion: {notion_url}
Topics: {topics}
Outcome: {status}
Decision: {key decision made} | OR Key finding: {reusable insight}
Tags: session-stub, {project}, {topics}
```

Use when: Plan exists, session completed, need persistent index.
**Required**: at least one of `Decision:` or `Key finding:` must be non-empty.
If neither applies → do not store a stub (session had no extractable knowledge).

### 2. Conventions & References
Reusable knowledge across sessions:

| Tier | Tags | TTL | Use for |
|------|------|-----|---------|
| T1 Core | `reference`, `identity`, `critical` | ∞ | IDs, paths, never obsolete |
| T2 Stable | `convention`, `preference`, `architecture` | 12 months | Workflows, patterns |
| T3 Tooling | `tooling`, `project` | 6 months | Commands, active configs |
| T4 Ephemeral | `temp`, `session` | 1 month | Immediate context |

Tier auto-detected from tags. Decay handles obsolescence.

## Anti-patterns (DO NOT store)

- ❌ Technical bugfixes → source code is reference
- ❌ Standard CLI commands → discoverable via --help
- ❌ Config file contents → already persisted on disk
- ❌ Lists that change often → quickly obsolete
- ❌ Full session content → use stub with pointers
- ❌ Generic session summaries → use curated stubs only
- ❌ "Completed" stubs with no Decision/Key finding → pure log noise
- ❌ Skill/plan scaffolding text → noise, not knowledge

## Workflow

1. Identify what to store:
   - Session completed? → Create stub (Plan + Notion refs)
   - Reusable pattern? → Create convention/reference
2. Check duplicates via `retrieve_memory` — skip if similarity >0.85 with existing
3. `store_memory` with appropriate tags
4. Auto-rate via HTTP:
   ```
   curl -X POST http://127.0.0.1:4242/api/quality/memories/{hash}/rate \
     -H "Content-Type: application/json" \
     -d '{"rating":1,"feedback":"Curated"}'
   ```

## Output

```
✓ {N} memories stored:
  - [session-stub] {title} (tier:T3)
  - [convention] {title} (tier:T2)
```

Or: "No relevant metadata to store"
