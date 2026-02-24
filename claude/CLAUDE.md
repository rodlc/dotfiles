# Global Instructions

## Context
MCP Memory stores personal context. Query tags: identity, paths, preferences, architecture, finance.

## Environment
Editor: Zed | Dir: ~/Code | Web: Enabled
MCP/Dotfiles: Query memory before changes (tags: mcp, dotfiles, critical)

## Response
Structure: Conclusion → details | Certainty: Proven → Probable → Possible
Language: English (code/docs/commits) | French (conversational)
Style: Working > elegant | Minimal > complete | Robust > optimal | No fluff

### Formatting (plans, summaries, structured output)
Telegraphic — fragments > sentences, 1 idea = 1 line, no filler.
Context ≤ 3 lines. Every section earns its space.
Plan = living doc: carry full session context, condense as it grows.
Use structure to replace prose:
- Data → tables ┌─┬─┐  Flow → arrows (→)  Lists → trees ├── └──
- Frames: ╔═╗ ╠═╣ ╚═╝  Headers: ════ major ──── minor
- Status: ✓ done ✗ rejected ⚠ risk ► action

## Code
Changes: Minimal | Commits: Atomic
Git: Team → branch/story | Personal → master direct
Before PR: pull main → verify → check assets/migrations
Rails TDD: test → route → controller → model → view

## Config
Source: `~/Code/rodlc/dotfiles/claude/` — query memory (tags: dotfiles, mcp) before edits

## Ollama Delegation
Local Ollama (qwen3:14b, fallback qwen3:8b) via MCP for token-heavy grunt work.
Keep on Claude: complex reasoning, multi-file architecture, debugging, tool-calling chains.

**MUST delegate** (proactively, not on request):
- Single-file review/explain → `ollama_review_file`, `ollama_explain_file`
- Multi-file scan → `ollama_analyze_files`
- Summarize long text/logs → `ollama_general_task`
- Generate test boilerplate → `ollama_general_task`
- Extract/transform data from files → `ollama_general_task`

Trigger: if task is read-only analysis of 1+ files AND doesn't need tool-calling → delegate.
`ollama_general_task`: param `task` (not `prompt`), `context` optional.

## Raycast MCP
When user shares/references a screenshot, capture, or clipboard content:
- Clipboard → `mcp__mcp-raycast-clipboard__clipboard_read`
- Recent screenshots → `mcp__mcp-raycast-clipboard__raycast_recent_images`
- Preview (token-efficient) → `get_thumbnail` then Read if needed
- Metadata only → `get_image_metadata`

## Dotfiles
Source: `~/Code/rodlc/dotfiles/` | Workspace: `~/Code/rodlc/workspace/`
Paths: NEVER hardcode username. Use $HOME (shell), Path.home() (python),
       __HOME__ (plists), ~/ (claude settings), ${HOME} (mcp.json templates)
Plists: always use __HOME__ placeholder, sed at install time
MCP config: .mcp.json is a template, expanded by mcp-sync.sh (envsubst)
Install: install.sh (system+dotfiles) then workspace-install.sh (MCP servers)
Version manager: mise (single tool for bun/node/python/ruby/go)
Runtime: bun preferred for JS/TS MCP servers, python for memory-service
