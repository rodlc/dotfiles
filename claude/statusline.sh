#!/bin/bash
COST_LIMIT=30.00  # Promo Noël 2x : $30 / fenêtre 5h

input=$(cat)
dir=$(echo "$input" | jq -r '.workspace.current_dir' | xargs basename)
branch=$(git -C "$(echo "$input" | jq -r '.workspace.current_dir')" branch --show-current 2>/dev/null || echo "-")

# Modèle : extraire display_name (ou fallback sur id simplifié)
model=$(echo "$input" | jq -r '
  if .model | type == "object" then
    (.model.display_name // (.model.id | sub("claude-(?<m>[a-z]+).*"; "\(.m | ascii_upcase[0:1] + .[1:])")))
  else
    (.model | sub("claude-(?<m>[a-z]+).*"; "\(.m | ascii_upcase[0:1] + .[1:])"))
  end // "?"
')

# Contexte %
ctx=$(echo "$input" | jq -r '
  ((.context_window.current_usage.input_tokens // 0) +
   (.context_window.current_usage.cache_read_input_tokens // 0)) * 100 /
  (.context_window.context_window_size // 200000) | floor')

# Quota persisté par fenêtre de 5h glissante
quota_file="$HOME/.claude/quota-window.json"
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
session_id=$(echo "$input" | jq -r '.session_id // ""')

# Timestamp actuel
now=$(date +%s)

# Lire état précédent
if [ -f "$quota_file" ] && [ -s "$quota_file" ]; then
  sessions_json=$(jq -c '.sessions // {}' "$quota_file" 2>/dev/null || echo '{}')
else
  sessions_json='{}'
fi

# Mettre à jour session courante avec gestion reset fenêtre
sessions_json=$(echo "$sessions_json" | jq -c --arg sid "$session_id" --argjson cost "$session_cost" --argjson now "$now" '
  # Normaliser sessions existantes (ajouter cost_at_reset si absent)
  to_entries
  | map(.value = (
      if .value | type == "object" then
        .value | .cost_at_reset = (.cost_at_reset // 0)
      else
        {cost: .value, first_seen: $now, cost_at_reset: 0}
      end
    ))
  | from_entries
  # Mettre à jour session courante
  | if .[$sid] then
      if ($now - .[$sid].first_seen) > 18000 then
        # Fenêtre expirée - reset avec baseline
        .[$sid] = {cost: $cost, first_seen: $now, cost_at_reset: $cost}
      else
        # Fenêtre active - update cost seulement
        .[$sid].cost = $cost
      end
    else
      # Nouvelle session
      .[$sid] = {cost: $cost, first_seen: $now, cost_at_reset: 0}
    end
  # Filtrer autres sessions expirées (garder courante)
  | to_entries
  | map(select(.key == $sid or (($now - .value.first_seen) <= 18000)))
  | from_entries
')

# Trouver session la plus ancienne pour reset time
oldest_seen=$(echo "$sessions_json" | jq '[.[] | select(type == "object") | .first_seen] | min // 0' 2>/dev/null)
oldest_seen=${oldest_seen:-0}
if [ -z "$oldest_seen" ] || [ "$oldest_seen" -eq 0 ]; then
  oldest_seen=$now
fi

# Calculer reset time = oldest_seen + 5h
reset_time=$((oldest_seen + 18000))
reset_h=$(date -r "$reset_time" +%H 2>/dev/null || echo "00")
reset_m=$(date -r "$reset_time" +%M 2>/dev/null || echo "00")

# Total = somme des coûts fenêtre (cost - cost_at_reset)
total_cost=$(echo "$sessions_json" | jq '[.[] | if type == "object" then (.cost - .cost_at_reset) else . end] | add // 0' 2>/dev/null || echo 0)

# Sauvegarder
echo "$sessions_json" | jq '{sessions: .}' > "$quota_file" 2>/dev/null

# Calculer %
quota=$(echo "scale=0; $total_cost * 100 / $COST_LIMIT" | bc 2>/dev/null || echo 0)
[ $quota -gt 100 ] && quota=100

printf "📁 %s  🌿 %s  🤖 %s  🧠 %d%%  📊 Max5 ~%d%% 🔄 %s:%s" \
  "$dir" "$branch" "$model" "$ctx" "$quota" "$reset_h" "$reset_m"
