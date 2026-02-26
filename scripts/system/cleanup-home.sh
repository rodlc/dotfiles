#!/bin/bash
# cleanup-home.sh — Periodic home directory cleanup
# Usage: cleanup-home.sh          (dry-run, shows what would be deleted)
#        cleanup-home.sh --apply  (actually delete)
set -euo pipefail

DRY_RUN=true
[[ "${1:-}" == "--apply" ]] && DRY_RUN=false

TOTAL_BYTES=0

size_bytes() {
  du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
}

human_size() {
  local bytes=$1
  if (( bytes >= 1073741824 )); then
    printf "%.1f GB" "$(echo "scale=1; $bytes / 1073741824" | bc)"
  elif (( bytes >= 1048576 )); then
    printf "%.0f MB" "$(echo "scale=0; $bytes / 1048576" | bc)"
  elif (( bytes >= 1024 )); then
    printf "%.0f KB" "$(echo "scale=0; $bytes / 1024" | bc)"
  else
    printf "%d B" "$bytes"
  fi
}

remove_item() {
  local target="$1" reason="$2"
  if [[ -e "$target" ]]; then
    local bytes
    bytes=$(size_bytes "$target")
    TOTAL_BYTES=$((TOTAL_BYTES + bytes))
    if $DRY_RUN; then
      printf "  %-45s %8s  %s\n" "$target" "$(human_size "$bytes")" "$reason"
    else
      rm -rf "$target"
      printf "  🗑  %-42s %8s\n" "$target" "$(human_size "$bytes")"
    fi
  fi
}

# ════════════════════════════════════════════════════════════════
# Section 1 — Residual tools (safe to delete entirely)
# ════════════════════════════════════════════════════════════════
echo "── Residual tools ──"
remove_item "$HOME/.bundle"         "Bundler cache, no Ruby projects"
remove_item "$HOME/go"              "GOPATH residual"
remove_item "$HOME/.cursor"         "Cursor IDE, unused"
remove_item "$HOME/.bun/bin"        "Redundant with mise-managed bun"
remove_item "$HOME/.bun/install"    "Bun install cache, regenerable"
echo ""

# ════════════════════════════════════════════════════════════════
# Section 2 — Claude Code maintenance
# ════════════════════════════════════════════════════════════════
echo "── Claude Code maintenance ──"
# Backups
if [[ -d "$HOME/.claude/backups" ]]; then
  for f in "$HOME/.claude/backups"/*; do
    [[ -e "$f" ]] && remove_item "$f" "Old .claude.json snapshot"
  done
fi
# Tmp
if [[ -d "$HOME/.claude/tmp" ]]; then
  for f in "$HOME/.claude/tmp"/*; do
    [[ -e "$f" ]] && remove_item "$f" "Temp file"
  done
fi
# Debug logs older than 7 days
if [[ -d "$HOME/.claude/debug" ]]; then
  while IFS= read -r -d '' f; do
    remove_item "$f" "Debug log >7 days"
  done < <(find "$HOME/.claude/debug" -type f -mtime +7 -print0 2>/dev/null)
fi
# Plans older than 30 days
if [[ -d "$HOME/.claude/plans" ]]; then
  while IFS= read -r -d '' f; do
    remove_item "$f" "Plan >30 days"
  done < <(find "$HOME/.claude/plans" -type f -mtime +30 -print0 2>/dev/null)
fi
# Root-level .claude.json backups (accumulate on every restart)
for f in "$HOME"/.claude.json.backup.*; do
  [[ -e "$f" ]] && remove_item "$f" "Claude CLI backup"
done
echo ""

# ════════════════════════════════════════════════════════════════
# Section 3 — Purgeable caches (regenerable)
# ════════════════════════════════════════════════════════════════
echo "── Purgeable caches ──"
remove_item "$HOME/.cache/pre-commit"                "pre-commit venvs, regenerable"
remove_item "$HOME/.cache/torch"                     "PyTorch model cache, regenerable"
remove_item "$HOME/Library/Caches/go-build"          "Go build cache, no active projects"
remove_item "$HOME/Library/Caches/pip"               "pip cache"
remove_item "$HOME/Library/Caches/loom-updater"      "Loom updater"
remove_item "$HOME/Library/Caches/node-gyp"          "Node native addon cache"
remove_item "$HOME/Library/Caches/notion.id.ShipIt"  "Notion auto-updater"
remove_item "$HOME/Library/Caches/bun"               "Bun runtime cache"
remove_item "$HOME/Library/Caches/antidote"           "Zsh plugin cache"
remove_item "$HOME/Library/Caches/claude-cli-nodejs"  "Claude CLI cache"

if command -v brew &>/dev/null; then
  brew_size=$(du -sk "$HOME/Library/Caches/Homebrew" 2>/dev/null | awk '{print $1 * 1024}')
  TOTAL_BYTES=$((TOTAL_BYTES + ${brew_size:-0}))
  if $DRY_RUN; then
    printf "  %-45s %8s  %s\n" "Homebrew cleanup" "$(human_size "${brew_size:-0}")" "brew cleanup -s"
  else
    brew cleanup -s 2>/dev/null || true
    brew autoremove 2>/dev/null || true
    echo "  🗑  Homebrew cleanup done"
  fi
fi
echo ""

# ════════════════════════════════════════════════════════════════
# Section 4 — Trash + old downloads
# ════════════════════════════════════════════════════════════════
echo "── Trash + old downloads ──"
if [[ -d "$HOME/.Trash" ]] && [[ -n "$(ls -A "$HOME/.Trash" 2>/dev/null)" ]]; then
  trash_bytes=$(size_bytes "$HOME/.Trash")
  TOTAL_BYTES=$((TOTAL_BYTES + trash_bytes))
  if $DRY_RUN; then
    printf "  %-45s %8s  %s\n" "~/.Trash/*" "$(human_size "$trash_bytes")" "Empty trash"
  else
    rm -rf "$HOME/.Trash"/*
    printf "  🗑  Trash emptied (%s)\n" "$(human_size "$trash_bytes")"
  fi
fi

# Zsh sessions older than 30 days
if [[ -d "$HOME/.zsh_sessions" ]]; then
  while IFS= read -r -d '' f; do
    remove_item "$f" "Zsh session >30 days"
  done < <(find "$HOME/.zsh_sessions" -type f -mtime +30 -print0 2>/dev/null)
fi

# Downloads older than 90 days
old_downloads=0
while IFS= read -r -d '' f; do
  old_downloads=$((old_downloads + 1))
  remove_item "$f" "Download >90 days"
done < <(find "$HOME/Downloads" -maxdepth 1 -type f -mtime +90 -print0 2>/dev/null)
[[ $old_downloads -eq 0 ]] && echo "  (no old downloads)"
echo ""

# ════════════════════════════════════════════════════════════════
# Section 5 — Empty directory cleanup
# ════════════════════════════════════════════════════════════════
echo "── Empty directories ──"
empty_count=0
while IFS= read -r -d '' dir; do
  empty_count=$((empty_count + 1))
  if $DRY_RUN; then
    printf "  %-45s %8s  %s\n" "$dir" "0 B" "Empty, will remove"
  else
    rmdir "$dir"
    printf "  🗑  %-42s %s\n" "$dir" "(empty)"
  fi
done < <(find "$HOME" -maxdepth 1 -type d -empty -print0 2>/dev/null)
[[ $empty_count -eq 0 ]] && echo "  (none)"
echo ""

# ════════════════════════════════════════════════════════════════
# Report
# ════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════"
if $DRY_RUN; then
  echo "DRY RUN — Total recoverable: $(human_size "$TOTAL_BYTES")"
  echo "Run with --apply to delete."
else
  echo "Cleaned: $(human_size "$TOTAL_BYTES")"
fi
echo ""

# Notable large dirs (not cleaned, for awareness)
echo "── Notable (not cleaned) ──"
for dir in "$HOME/.ollama" "$HOME/.local/share/mise" "$HOME/.cache/mcp_memory"; do
  [[ -d "$dir" ]] && printf "  %-45s %8s\n" "$dir" "$(du -sh "$dir" 2>/dev/null | awk '{print $1}')"
done
echo ""
df -h "$HOME" | tail -1 | awk '{print "💾 Disk: " $5 " used (" $3 " / " $2 ")"}'
