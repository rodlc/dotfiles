# Memory Storage Patterns

## Types and Retention

| Type | Tag | Retention | Examples |
|------|-----|-----------|----------|
| **semantic** | reference | 180d | ☑️ Convention, API pattern, market data |
| **episodic** | standard | 90d | ☑️ Decision with context, trade-off, bug fix |
| **procedural** | critical | 365d | ☑️ Workflow, hook, shell command |

## Format

```python
store_memory(content="[TYPE] Subject", metadata={"tags": "reference", "type": "semantic"})
```

## Examples

### Semantic (reference)
```python
store_memory(
    content="Rails convention: Controllers in app/controllers inherit from ApplicationController",
    metadata={"tags": "reference,rails,convention", "type": "semantic"}
)
```

### Episodic (standard)
```python
store_memory(
    content="Decision: Used PostgreSQL JSONB for flexible schema instead of separate tables. Trade-off: flexibility vs query performance",
    metadata={"tags": "standard,decision,postgresql", "type": "episodic"}
)
```

### Procedural (critical)
```python
store_memory(
    content="Workflow: Before Rails PR → git pull main → rails db:migrate → check for assets/migrations changes",
    metadata={"tags": "critical,workflow,rails", "type": "procedural"}
)
```

## DO NOT Store

❌ Content already in git
❌ Session temporary data
❌ Verbatim conversations
