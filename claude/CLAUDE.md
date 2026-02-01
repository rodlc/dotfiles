# Global Instructions

## Context
MCP Memory stores all personal context. Query via `mcp__memory__retrieve_memory`:
- **Identity:** Name, NIR, France Travail, contact, addresses
- **Paths:** DocumentPaths (CNI, RIB, CV, budgets), GoogleDriveArchitecture
- **Preferences:** Personality (SLI-Te 5w6), Conventions (naming, Git, Rails TDD), EmailStyle
- **Architecture:** AreasArchitecture (20 Areas), ProjectsArchitecture, NotionIDs, ClaudeConfig
- **Finance:** FinanceReferences (Yomoni, Boursorama), CurrentProjects

## Environment
Editor: Zed | Dir: ~/Code | Web: Enabled
MCP/Dotfiles: Query memory before changes (tags: mcp, dotfiles, critical)

## Response
Structure: Conclusion → details | Certainty: Proven → Probable → Possible
Principles: Pragmatic, frugal, antifragile | Tone: Concise, dry wit
Language: English for code/docs/commits (formal written content), French for conversational (informal)

### Formatting (plans, summaries, structured output)
Unicode box-drawing:
- Frames: ╔═╗ ╠═╣ ╚═╝ (major sections, problem statements)
- Tables: ┌─┬─┐ ├─┼─┤ └─┴─┘ (data grids, comparisons)
- Trees: ├── └── (hierarchies, file structures)
- Status: ✓ done ✗ rejected ⚠ risk ► action
- Headers: ════ major ──── minor

## Code
Changes: Minimal | Commits: Atomic
Git: Team → branch/story | Personal → master direct
Before PR: pull main → verify → check assets/migrations
Rails TDD: test → route → controller → model → view

## Memory
Store cross-session learnings. Tags: `critical` (365d), `reference` (180d), `standard` (90d).
See `~/.claude/agent_docs/memory-patterns.md` for format details.

## Config
Source: `~/Code/rodlc/dotfiles/claude/` → `~/.claude/`
Patterns: See `~/.claude/agent_docs/` for formatting, memory details

## Tools
- YouTube transcripts: `youtube_transcript_api VIDEO_ID --format text --languages fr en`

## Commands
/notion [priority] [title] → Save to Notion Tasks
