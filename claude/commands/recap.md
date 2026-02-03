---
description: Finalize session plan with progress and next steps
argument-hint: ""
---

Update the current session plan with progress made and next steps.

## Workflow

1. **Identify session plan**:
   - Look for plan file path in system prompt
   - If no plan exists → create retroactive plan

2. **Analyze session**:
   - What was accomplished
   - Current status
   - What remains to do

3. **Update plan file**:
   - Add/update "## Result" section with status
   - Add "## Next steps" if task incomplete
   - **Use native Plan Mode formatting** (CLAUDE.md: box-drawing, frames, tables)

4. **Output**: Brief confirmation of changes

## Formatting

Write like Plan Mode naturally writes — follow CLAUDE.md formatting rules:
- Frames: ╔═╗ ╠═╣ ╚═╝ for major sections
- Tables: ┌─┬─┐ ├─┼─┤ └─┴─┘ for data
- Trees: ├── └── for hierarchies
- Status: ✓ done ✗ rejected ⚠ risk ► action

**No templates** — adapt to existing plan structure and context.
