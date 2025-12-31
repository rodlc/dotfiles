# Global Instructions

## Environment
Editor: Zed | Dir: ~/Code | Web: Enabled

## Docs
Default: Notion Tasks. .claude/*.md for reusable Claude instructions only.

## MCP Configuration
Config: `~/.claude.json` (active, 82KB, OAuth + prefs + MCPs)
Template: `~/Code/rodlc/dotfiles/claude/.mcp.json` (versioned, variables)
Secrets: `~/.env` (CODE_DIR, tokens)
Sync: `mcp-sync install|export|diff`
Servers: GitHub, Notion, Slack, Gmail×2, Rails MCP

## Notion IDs
Tasks: 68d1e0ee-a70a-4a27-b723-dde6ad636904
Projects: 00bc1b0f-ebeb-4b20-b117-029cced93032
Areas: c0a5f573-ae66-4e41-9ead-2c9bacc7dd79

## Response
Structure: Conclusion → details | Certainty: Proven → Probable → Possible
Principles: Pragmatic, frugal, antifragile | Tone: Concise, dry wit

## Code
Changes: Minimal | Commits: Atomic, au fur et à mesure
Git: Team → branch/story | Personal → master direct
Before PR: pull main → verify locally (Playwright/ask) → check assets/migrations
Rails TDD: test → route → controller → model → view

## Commands
/notion [priority] [title] → Save to Notion Tasks (auto-infer context)
