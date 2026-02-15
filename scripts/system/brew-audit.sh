#!/usr/bin/env bash
# brew-audit.sh — Audit Homebrew installations by real usage
# Scores casks via Spotlight metadata + login items
# Scores formulae via shell history + reverse dependencies

set -euo pipefail

# ════════════════════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════════════════════

BREWFILE="${1:-$HOME/Code/rodlc/dotfiles/Brewfile}"
ZSH_HISTORY="$HOME/.zsh_history"
OUTPUT_DIR="${TMPDIR:-/tmp}/brew-audit-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# Score thresholds
KEEP_THRESHOLD=6
REVIEW_THRESHOLD=3

# ════════════════════════════════════════════════════════════════════════════
# Utility functions
# ════════════════════════════════════════════════════════════════════════════

normalize() {
  # Normalize value to 0-10 scale
  # Args: value, max_value
  local val=${1:-0}
  local max=${2:-100}

  # Ensure val is numeric
  [[ -z "$val" || ! "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]] && val=0
  [[ $max -eq 0 ]] && max=1  # avoid division by zero

  awk "BEGIN {printf \"%.1f\", (${val} / ${max}) * 10}"
}

get_recency_score() {
  # Convert last used date to recency score
  local last_used=$1
  if [[ -z "$last_used" || "$last_used" == "(null)" ]]; then
    echo "0"
    return
  fi

  local now=$(date +%s)
  local last_timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$last_used" +%s 2>/dev/null || echo "0")
  local days_ago=$(( (now - last_timestamp) / 86400 ))

  if [[ $days_ago -le 1 ]]; then echo "10"
  elif [[ $days_ago -le 7 ]]; then echo "8"
  elif [[ $days_ago -le 30 ]]; then echo "5"
  elif [[ $days_ago -le 90 ]]; then echo "2"
  else echo "0"
  fi
}

is_login_item() {
  # Check if app is in Login Items or LaunchAgents
  local app_name=$1

  # Check Login Items via osascript
  if osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -qi "$app_name"; then
    echo "10"
    return
  fi

  # Check LaunchAgents
  if find ~/Library/LaunchAgents /Library/LaunchAgents 2>/dev/null | xargs grep -li "$app_name" >/dev/null 2>&1; then
    echo "10"
    return
  fi

  echo "0"
}

is_running() {
  # Check if process is currently running
  local app_name=$1
  if ps aux | grep -v grep | grep -qi "$app_name"; then
    echo "10"
  else
    echo "0"
  fi
}

# ════════════════════════════════════════════════════════════════════════════
# Cask scoring
# ════════════════════════════════════════════════════════════════════════════

score_cask() {
  local cask=$1
  local app_path="/Applications/${cask}.app"

  # Try common name variations
  if [[ ! -d "$app_path" ]]; then
    # Try with capitalization variations
    for candidate in /Applications/*.app; do
      if [[ $(basename "$candidate" .app | tr '[:upper:]' '[:lower:]' | tr -d ' -') == $(echo "$cask" | tr '[:upper:]' '[:lower:]' | tr -d ' -') ]]; then
        app_path="$candidate"
        break
      fi
    done
  fi

  if [[ ! -d "$app_path" ]]; then
    echo "0|0|0|0|0.0|NOT_FOUND"
    return
  fi

  # Get Spotlight metadata
  local last_used=$(mdls -name kMDItemLastUsedDate -raw "$app_path" 2>/dev/null || echo "(null)")
  local use_count=$(mdls -name kMDItemUseCount -raw "$app_path" 2>/dev/null || echo "0")

  # Clean up metadata
  [[ "$last_used" == "(null)" ]] && last_used=""
  [[ "$use_count" == "(null)" ]] && use_count="0"

  # Calculate component scores
  local recency_score=$(get_recency_score "$last_used")
  local frequency_score=$(normalize "$use_count" 200)  # normalize to max 200 uses
  local cpu_score=$(is_running "$(basename "$app_path" .app)")
  local login_score=$(is_login_item "$(basename "$app_path" .app)")

  # Calculate weighted total
  local total=$(awk "BEGIN {printf \"%.1f\", ($recency_score * 0.3) + ($frequency_score * 0.2) + ($cpu_score * 0.3) + ($login_score * 0.2)}")

  # Determine status
  local status
  if awk "BEGIN {exit !($total >= $KEEP_THRESHOLD)}"; then
    status="KEEP"
  elif awk "BEGIN {exit !($total >= $REVIEW_THRESHOLD)}"; then
    status="REVIEW"
  else
    status="DROP"
  fi

  echo "$recency_score|$frequency_score|$cpu_score|$login_score|$total|$status"
}

# ════════════════════════════════════════════════════════════════════════════
# Formula scoring
# ════════════════════════════════════════════════════════════════════════════

score_formula() {
  local formula=$1

  # Count shell history hits
  local history_hits=0
  if [[ -f "$ZSH_HISTORY" ]]; then
    history_hits=$(grep -c "^: [0-9]*:0;$formula" "$ZSH_HISTORY" 2>/dev/null || echo "0")
    [[ -z "$history_hits" ]] && history_hits=0
  fi

  # Count reverse dependencies
  local reverse_deps=$(brew uses --installed "$formula" 2>/dev/null | wc -l | tr -d ' ')
  [[ -z "$reverse_deps" ]] && reverse_deps=0

  # Check if explicitly in Brewfile
  local in_brewfile=0
  if grep -q "^brew [\"']$formula[\"']" "$BREWFILE" 2>/dev/null; then
    in_brewfile=10
  fi

  # Calculate component scores (ensure numeric values)
  local history_score=$(normalize "${history_hits:-0}" 50)  # normalize to max 50 uses
  local deps_score=$(normalize "${reverse_deps:-0}" 10)     # normalize to max 10 dependents

  # Ensure scores are numeric
  [[ -z "$history_score" ]] && history_score="0.0"
  [[ -z "$deps_score" ]] && deps_score="0.0"

  # Calculate weighted total
  local total=$(awk "BEGIN {printf \"%.1f\", (${history_score:-0} * 0.4) + (${deps_score:-0} * 0.3) + (${in_brewfile:-0} * 0.3)}")
  [[ -z "$total" ]] && total="0.0"

  # Determine status
  local status="DROP"
  if awk "BEGIN {exit !(${total:-0} >= $KEEP_THRESHOLD)}"; then
    status="KEEP"
  elif awk "BEGIN {exit !(${total:-0} >= $REVIEW_THRESHOLD)}"; then
    status="REVIEW"
  fi

  echo "$history_score|$deps_score|$in_brewfile|$total|$status"
}

# ════════════════════════════════════════════════════════════════════════════
# Main audit
# ════════════════════════════════════════════════════════════════════════════

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                       HOMEBREW AUDIT — Usage Analysis                        ║"
echo "╠══════════════════════════════════════════════════════════════════════════════╣"
echo "║  Brewfile: $BREWFILE"
echo "║  Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo

# ────────────────────────────────────────────────────────────────────────────
# Section 1: Casks
# ────────────────────────────────────────────────────────────────────────────

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║  CASKS — Scoring based on Spotlight metadata + Login Items                  ║"
echo "╠══════════════════════════════════════════════════════════════════════════════╣"
echo "║  Cask                     │ Recen │ Freq │ CPU │ Login │ Score │ Status     ║"
echo "╠═══════════════════════════╪═══════╪══════╪═════╪═══════╪═══════╪════════════╣"

# Get all installed casks
brew list --cask 2>/dev/null | sort | while read -r cask; do
  result=$(score_cask "$cask")
  IFS='|' read -r recency freq cpu login total status <<< "$result"

  # Color code status
  icon=""
  case $status in
    KEEP)      icon="🟢" ;;
    REVIEW)    icon="🟡" ;;
    DROP)      icon="🔴" ;;
    NOT_FOUND) icon="⚠️" ;;
  esac

  printf "║  %-24s │ %5s │ %4s │ %3s │ %5s │ %5s │ %s %-10s ║\n" \
    "$cask" "$recency" "$freq" "$cpu" "$login" "$total" "$icon" "$status"
  echo "$cask|$recency|$freq|$cpu|$login|$total|$status" >> "$OUTPUT_DIR/casks.csv"
done

echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo

# ────────────────────────────────────────────────────────────────────────────
# Section 2: Formulae
# ────────────────────────────────────────────────────────────────────────────

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║  FORMULAE — Scoring based on shell history + reverse deps                   ║"
echo "╠══════════════════════════════════════════════════════════════════════════════╣"
echo "║  Formula                  │ Hist │ Deps │ Brew │ Score │ Status            ║"
echo "╠═══════════════════════════╪══════╪══════╪══════╪═══════╪═══════════════════╣"

# Get top-level packages (brew leaves)
brew leaves 2>/dev/null | sort | while read -r formula; do
  result=$(score_formula "$formula")
  IFS='|' read -r hist deps brewfile total status <<< "$result"

  # Color code status
  icon=""
  case $status in
    KEEP)   icon="🟢" ;;
    REVIEW) icon="🟡" ;;
    DROP)   icon="🔴" ;;
  esac

  printf "║  %-24s │ %4s │ %4s │ %4s │ %5s │ %s %-13s ║\n" \
    "$formula" "$hist" "$deps" "$brewfile" "$total" "$icon" "$status"
  echo "$formula|$hist|$deps|$brewfile|$total|$status" >> "$OUTPUT_DIR/formulae.csv"
done

echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo

# ────────────────────────────────────────────────────────────────────────────
# Section 3: Drift detection (installed but not in Brewfile)
# ────────────────────────────────────────────────────────────────────────────

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║  DRIFT — Installed but NOT in Brewfile                                      ║"
echo "╠══════════════════════════════════════════════════════════════════════════════╣"

# Casks not in Brewfile
echo "║  Casks:"
brew list --cask 2>/dev/null | while read -r cask; do
  if ! grep -q "cask [\"']$cask[\"']" "$BREWFILE" 2>/dev/null; then
    echo "║    - $cask"
  fi
done

echo "║"
echo "║  Formulae:"
brew leaves 2>/dev/null | while read -r formula; do
  if ! grep -q "brew [\"']$formula[\"']" "$BREWFILE" 2>/dev/null; then
    echo "║    - $formula"
  fi
done

echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo

# ────────────────────────────────────────────────────────────────────────────
# Summary
# ────────────────────────────────────────────────────────────────────────────

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║  SUMMARY                                                                     ║"
echo "╠══════════════════════════════════════════════════════════════════════════════╣"
echo "║  Classification thresholds:                                                  ║"
echo "║    🟢 KEEP    → score ≥ $KEEP_THRESHOLD                                                      ║"
echo "║    🟡 REVIEW  → score $REVIEW_THRESHOLD-$((KEEP_THRESHOLD-1))                                                     ║"
echo "║    🔴 DROP    → score < $REVIEW_THRESHOLD                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
