---
description: Search memories by tags
---

Find memories by tags or keywords.

## Usage

```
/memory-find [tags]
```

## Examples

```
/memory-find reference
→ All reference memories (conventions, APIs)

/memory-find critical,identity
→ Critical identity memories (NIR, contacts)

/memory-find tooling notion
→ Tooling memories related to Notion
```

## Output

Found X memories matching tags [tags]:

1. [timestamp] Content preview... (tags: X, Y, Z)
2. [timestamp] Content preview... (tags: X, Y, Z)
...

Use `retrieve_memory` for full content.
