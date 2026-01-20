---
description: Quick memory store with auto-classification
---

Store memory with automatic type/tag inference.

## Auto-classification + Rating

**By content pattern:**
- Workflow/command → `procedural` + `critical` (365d) + **rate=1**
- Convention/API → `semantic` + `reference` (180d) + **rate=1**
- Decision/context → `episodic` + `standard` (90d) + *(no rating)*

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
✓ Quality: rated +1 (curated)  ← for critical/reference only
