---
name: delegate
description: >
  ALWAYS use this skill instead of analyzing files directly when the user
  asks for: file review, code review, code explanation, summarization,
  multi-file analysis, or test generation. Loads Ollama tools via ToolSearch
  and delegates read-only work to local qwen3:14b.
argument-hint: "[review|explain|analyze|summarize|tests|task] [file or description]"
allowed-tools: "mcp__ollama__* ToolSearch Read Glob"
user-invocable: true
---

# Delegate to Ollama

Route token-heavy read-only work to local Ollama MCP (qwen3:14b, fallback qwen3:8b).

## Step 1 — Load Ollama tools

Call `ToolSearch` with query `+ollama` to load all `mcp__ollama__*` tools before proceeding.

## Step 2 — Parse arguments

Arguments: `$ARGUMENTS`

Parse the first word as the command, rest as params:

| Command | Ollama tool | Required params |
|---------|-------------|-----------------|
| `review <file_path>` | `ollama_review_file` | `file_path` (absolute path) |
| `explain <file_path>` | `ollama_explain_file` | `file_path` (absolute path) |
| `analyze <file_paths…> <task>` | `ollama_analyze_files` | `file_paths[]`, `task` |
| `summarize <text>` | `ollama_general_task` | `task` = full text to summarize |
| `tests <file_path> [framework]` | `ollama_write_tests` | Read file first → pass `code`, `framework` (default: infer from file) |
| `task <description>` | `ollama_general_task` | `task` = description, `context` optional |

If no command given or unrecognized, show the table above and ask user to clarify.

## Step 3 — Execute

- For `review` / `explain`: pass `file_path` as absolute path (expand `~` if needed).
- For `analyze`: `file_paths` is a JSON array of absolute paths; last token is the task description.
- For `tests`: Read the file first, pass content as `code` param.
- For `summarize` / `task`: pass remaining args as the `task` param (NOT `prompt`).

## Fallback

If Ollama tool call fails (timeout, connection error, model not found):
- Report the error clearly
- Do NOT silently retry with a Claude-side analysis
- Suggest: `/delegate task ...` with simpler input, or check Ollama status
