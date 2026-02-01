---
description: Rate top memories quality
---

Interactive quality rating for important memories via HTTP API.

## Workflow

⚠️ **IMPORTANT:** Use HTTP API on port 4242 (check with `lsof -nP -p $(pgrep -f run_http_server) | grep LISTEN`)

1. Get quality distribution: `curl http://127.0.0.1:4242/api/quality/distribution`
2. Identify 5-10 critical memories (identity, conventions, workflows)
3. For each memory:
   - Use `retrieve_memory` or `search_by_tag` to get the full memory
   - Extract the complete `content_hash` from the result
   - Rate via HTTP: `curl -X POST http://127.0.0.1:4242/api/quality/memories/{hash}/rate -H "Content-Type: application/json" -d '{"rating":1,"feedback":"description"}'`
4. Verify with distribution endpoint

**Rating scale (thumbs up/down):**
- 1: Thumbs up → quality_score = 0.6 × 1.0 + 0.4 × old_score (critical, frequently accessed)
- 0: Neutral → quality_score = 0.6 × 0.5 + 0.4 × old_score (useful but not critical)
- -1: Thumbs down → quality_score = 0.6 × 0.0 + 0.4 × old_score (low value, outdated)

## Targets

**Priority rating (rating=1, thumbs up):**
- Identity (NIR, contacts, addresses)
- Notion IDs (Tasks, Projects, Areas DBs)
- Core conventions (naming, Git workflow, TDD)
- Critical workflows (dotfiles, MCP config)
- Architecture references (GoogleDrive, Areas)

**Mark for removal (rating=-1, thumbs down):**
- Outdated info
- Duplicate content
- Session artifacts with 0 access_count

## Example

```bash
# Step 1: Find memory hash via MCP
# mcp__memory-service__retrieve_memory(query="email style", limit=1)
# Returns: content_hash: "5f50734171e9082fcfa86a988acfcb6bc9d40444709b765826f2a8a38aeef3d5"

# Step 2: Rate it via HTTP API (thumbs up)
curl -X POST http://127.0.0.1:4242/api/quality/memories/5f50734171e9082fcfa86a988acfcb6bc9d40444709b765826f2a8a38aeef3d5/rate \
  -H "Content-Type: application/json" \
  -d '{"rating":1,"feedback":"Critical email style reference"}' | jq

# Response: {"success":true,"new_quality_score":0.8,"old_quality_score":0.5}
```

## Output

## Quality Rating Summary

Rated X memories:
- 👍 High priority: X
- 👎 Remove: X

Average quality improved: X.XX → X.XX
