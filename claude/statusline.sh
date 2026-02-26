#!/bin/bash
COST_LIMIT=35.00

input=$(cat)

# ── 1. Parse all input in one jq call ──────────────────────────────
{
  read -r dir_full
  read -r dir
  read -r model
  read -r ctx
  read -r session_cost
  read -r session_id
} < <(echo "$input" | jq -r '
  (.workspace.current_dir // "/tmp"),
  (.workspace.current_dir // "/tmp" | split("/") | last),
  (if .model | type == "object" then
    (.model.display_name // (.model.id | sub("claude-(?<m>[a-z]+).*"; "\(.m | ascii_upcase[0:1] + .[1:])")))
  else
    (.model | sub("claude-(?<m>[a-z]+).*"; "\(.m | ascii_upcase[0:1] + .[1:])"))
  end // "?"),
  (((.context_window.current_usage.input_tokens // 0) +
    (.context_window.current_usage.cache_read_input_tokens // 0)) * 100 /
    (.context_window.context_window_size // 200000) | floor | tostring),
  (.cost.total_cost_usd // 0 | tostring),
  (.session_id // "")')

# ── 2. Git branch ──────────────────────────────────────────────────
branch=$(git -C "$dir_full" branch --show-current 2>/dev/null || echo "-")

# ── 3. Timestamp ───────────────────────────────────────────────────
now=$(date +%s)

# ── 4. Quota: read + reset + update + compute in one jq call ───────
quota_file="$HOME/.claude/quota-window.json"
[ -f "$quota_file" ] && [ -s "$quota_file" ] && prev_json=$(< "$quota_file") || prev_json='{"sessions":{},"last_reset":0}'

{
  read -r new_state
  read -r total_cost
  read -r last_reset
  read -r quota
  read -r next_reset_ts
  read -r time_left
} < <(printf '%s' "$prev_json" | jq -r \
  --argjson now "$now" \
  --arg sid "$session_id" \
  --argjson cost "$session_cost" \
  --argjson limit "$COST_LIMIT" '
  (.last_reset // 0) as $lr
  | (if ($now - $lr) >= 18000 then
      (.sessions // {} | to_entries | map(
        .value = (if .value | type == "object"
          then .value | .cost_at_reset = .cost
          else {cost: .value, first_seen: $now, cost_at_reset: .value} end)
      ) | from_entries) as $rs
      | {sessions: $rs, last_reset: $now}
    else {sessions: (.sessions // {}), last_reset: $lr}
    end) as $s
  | ($s.sessions
    | to_entries
    | map(.value = (if .value | type == "object"
        then .value | .cost_at_reset = (.cost_at_reset // 0)
        else {cost: .value, first_seen: $now, cost_at_reset: 0} end))
    | map(select(.key == $sid or (($now - .value.first_seen) <= 18000)))
    | from_entries
    | if .[$sid] != null then .[$sid].cost = $cost
      else .[$sid] = {cost: $cost, first_seen: $now, cost_at_reset: $cost} end
  ) as $sessions
  | {sessions: $sessions, last_reset: $s.last_reset} as $final
  | ($final.sessions | [.[] | if type == "object" then (.cost - .cost_at_reset) else . end] | add // 0) as $total
  | $final.last_reset as $reset
  | ($now - $reset) as $elapsed
  | (if ($elapsed > 300) and ($total > 0.01) then
      ($total * 3600 / $elapsed) as $burn
      | (($limit - $total) / $burn) as $hrs
      | "\($hrs | floor)h\(($hrs - ($hrs | floor)) * 60 | floor)m"
    else "--" end) as $tl
  | ($final | tojson),
    ($total | tostring),
    ($reset | tostring),
    ($total * 100 / $limit | floor | tostring),
    (($reset + 18000) | tostring),
    $tl')

[ -n "$new_state" ] && echo "$new_state" > "$quota_file"

# ── 5. Reset time + display ─────────────────────────────────────────
reset_time=$(date -r "$next_reset_ts" +%H:%M 2>/dev/null || echo "??:??")
cost_display=$(printf "%.2f" "$total_cost")

printf "📁 %s 🌿 %s 🤖 %s 🧠 %d%% 💰 \$%s (%d%%) 🔥 %s 🔄 %s" \
  "$dir" "$branch" "$model" "$ctx" \
  "$cost_display" "$quota" "$time_left" "$reset_time"
