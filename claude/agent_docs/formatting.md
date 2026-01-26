# Output Formatting

## Structured Documents
Use Unicode box-drawing for actionable documents:
- Frames: ╔═╗ ╠═╣ ╚═╝ (major sections)
- Tables: ┌─┬─┐ ├─┼─┤ └─┴─┘ (data grids)
- Trees: ├── └── (hierarchies)
- Status: ✓ done ✗ rejected ⚠ risk ► action
- Flow: ═══► phase ──► step ▼ transition
- Headers: ════ major ──── minor

## Rationale
- Markdown-KV format: 60.7% LLM accuracy vs 44% CSV ([source](https://www.improvingagents.com/blog/best-input-data-format-for-llms/))
- Structure improves Claude parsing ([source](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices))
- Token-efficient vs XML/JSON
