---
description: Rate top memories quality
---

Interactive quality rating for important memories.

## Workflow

⚠️ **IMPORTANT:** `rate_memory` requires the full content_hash, not just a preview.

1. `analyze_quality_distribution` → Find candidates
2. Identify 5-10 critical memories (identity, conventions, workflows)
3. For each memory:
   - Use `retrieve_memory` or `search_by_tag` to get the full memory
   - Extract the complete `content_hash` from the result
   - Call `rate_memory(hash=content_hash, rating=1-5)`
4. Verify with `retrieve_with_quality_boost`

**Rating scale:**
- 5: Critical, frequently accessed (identity, core conventions)
- 4: Important reference (architecture, workflows)
- 3: Useful standard (decisions, tooling)
- 2: Low value or outdated
- 1: Should be deleted

## Targets

**Priority rating (rating=5):**
- Identity (NIR, contacts, addresses)
- Notion IDs (Tasks, Projects, Areas DBs)
- Core conventions (naming, Git workflow, TDD)
- Critical workflows (dotfiles, MCP config)

**Mark for removal (rating=1-2):**
- Outdated info
- Duplicate content
- Session artifacts

## Example

```python
# Step 1: Find memory
result = retrieve_memory("email style", n_results=1)
# Returns: Hash: 5f50734171e9082fcfa86a988acfcb6bc9d40444709b765826f2a8a38aeef3d5

# Step 2: Rate it
rate_memory(
    hash="5f50734171e9082fcfa86a988acfcb6bc9d40444709b765826f2a8a38aeef3d5",
    rating=5
)
```

## Output

## Quality Rating Summary

Rated X memories:
- 👍 High priority: X
- 👎 Remove: X

Average quality improved: X.XX → X.XX
