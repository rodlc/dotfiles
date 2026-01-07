---
description: Extract metadata to MCP Memory
---

Extract metadata reusable across sessions, using tier-based storage.

## Storage Tiers

| Tier | Tags | TTL | Criteria |
|------|------|-----|----------|
| T1 Core | `reference`, `identity` | ∞ | IDs, critical paths, never obsolete |
| T2 Stable | `convention`, `preference` | 12 months | Workflows, established rules |
| T3 Tooling | `tooling`, `project` | 6 months | Commands, active project context |
| T4 Ephemeral | `temp`, `session` | 1 month | Disposable info, immediate context |

**Store directly** with appropriate tag. Decay handles obsolescence.

## Anti-patterns (DO NOT store)

- ❌ Technical bugfixes → source code is reference
- ❌ Standard CLI commands → discoverable via --help
- ❌ Config file contents → already persisted on disk
- ❌ Lists that change often → quickly obsolete
- ❌ Project-specific decisions → use /notion

## Workflow

1. Scan session for metadata candidates
2. Apply value test (3 questions)
3. Check duplicates via retrieve_memory
4. store_memory directly with appropriate tags

## Output

✓ N memories stored (or "No relevant metadata")
