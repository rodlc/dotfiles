---
description: Quick memory store with auto-classification
---

Store memory with automatic type/tag inference.

## Auto-classification

**By content pattern:**
- Workflow/command → `procedural` + `critical` (365d)
- Convention/API → `semantic` + `reference` (180d)
- Decision/context → `episodic` + `standard` (90d)

## Usage

```
/memory-store [TYPE] Content
```

Type optional, auto-inferred if omitted.

## Examples

```
/memory-store underscore_case 20% plus rapide
→ semantic + reference

/memory-store bw-pull unified dotfiles restore
→ procedural + critical

/memory-store Décision refactor avec TypeScript pour meilleure DX
→ episodic + standard
```

## Output

✓ Stored as [type] with tags [tags]
