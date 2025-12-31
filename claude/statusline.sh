#!/bin/bash
COST_LIMIT=36.00  # Limite Claude de base (sans promo)

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

# Quota persisté multi-sessions avec baseline
quota_file="$HOME/.claude/quota-window.json"
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
session_id=$(echo "$input" | jq -r '.session_id // ""')

# Timestamp actuel
now=$(date +%s)

# Lire état précédent
if [ -f "$quota_file" ] && [ -s "$quota_file" ]; then
  prev_state=$(cat "$quota_file")
  sessions_json=$(echo "$prev_state" | jq -c '.sessions // {}')
  last_reset=$(echo "$prev_state" | jq -r '.last_reset // 0')
else
  sessions_json='{}'
  last_reset=0
fi

# Vérifier si on doit reset (5h = 18000s)
if [ $((now - last_reset)) -ge 18000 ]; then
  # Reset : cost_at_reset = cost pour toutes les sessions
  sessions_json=$(echo "$sessions_json" | jq -c '
    to_entries
    | map(.value = (
        if .value | type == "object" then
          .value | .cost_at_reset = .cost
        else
          {cost: .value, first_seen: '"$now"', cost_at_reset: .value}
        end
      ))
    | from_entries
  ')
  last_reset=$now
fi

# Mettre à jour session courante avec baseline
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
      # Session existante - update cost seulement
      .[$sid].cost = $cost
    else
      # Nouvelle session - baseline le coût hérité
      .[$sid] = {cost: $cost, first_seen: $now, cost_at_reset: $cost}
    end
  # Filtrer autres sessions expirées (garder courante)
  | to_entries
  | map(select(.key == $sid or (($now - .value.first_seen) <= 18000)))
  | from_entries
')

# Total = somme des coûts fenêtre (cost - cost_at_reset)
total_cost=$(echo "$sessions_json" | jq '[.[] | if type == "object" then (.cost - .cost_at_reset) else . end] | add // 0' 2>/dev/null || echo 0)

# Sauvegarder
echo "$sessions_json" | jq --argjson reset "$last_reset" '{sessions: ., last_reset: $reset}' > "$quota_file" 2>/dev/null

# Calculer %
quota=$(echo "scale=0; $total_cost * 100 / $COST_LIMIT" | bc 2>/dev/null || echo 0)

printf "📁 %s  🌿 %s  🤖 %s  🧠 %d%%  📊 Max5 ~%d%%" \
  "$dir" "$branch" "$model" "$ctx" "$quota"
