#!/bin/bash
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Debug: log pour troubleshooting
echo "DEBUG: command='$command'" >> /tmp/claude-hook-debug.log

# DENY: Git destructif (vérifier AVANT les allows)
# Patterns stricts : flags doivent être des arguments séparés (pas dans noms de branches)
# Format: (FLAG_DIRECT|.*[[:space:]]FLAG)([[:space:]]|$) = flag juste après subcommand OU après espace, suivi d'espace ou fin
if [[ $command =~ git[[:space:]]+reset[[:space:]]+(--hard|.*[[:space:]]--hard)([[:space:]]|$) ]] || \
   [[ $command =~ git[[:space:]]+push[[:space:]]+((-f|--force)|.*[[:space:]](-f|--force))([[:space:]]|$) ]] || \
   [[ $command =~ git[[:space:]]+checkout[[:space:]]+--[[:space:]] ]] || \
   [[ $command =~ git[[:space:]]+clean[[:space:]]+(-[fFdDxX]|.*[[:space:]]-[fFdDxX])([[:space:]]|$) ]] || \
   [[ $command =~ git[[:space:]]+branch[[:space:]]+(-D|.*[[:space:]]-D)([[:space:]]|$) ]]; then
  echo "DEBUG: DENY! Destructive git command" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Destructive git command blocked for safety"}}'
  exit 0
fi

# DENY: rm récursif dangereux (chemins absolus ou home)
# Détecte -r, -R, -rf, -fr, -Rf, etc.
if [[ $command =~ ^rm[[:space:]] ]] && [[ $command =~ -[rRfF]*[rR][rRfF]* ]]; then
  # Bloque si chemin absolu (/) ou home (~) détecté
  if [[ $command =~ [[:space:]]/[^.] ]] || [[ $command =~ [[:space:]]~ ]]; then
    echo "DEBUG: DENY! rm recursive with absolute or home path" >> /tmp/claude-hook-debug.log
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"rm recursive with absolute or home path blocked"}}'
    exit 0
  fi
fi

# Commandes safe (même avec pipes/redirections)
if [[ $command =~ ^ls([[:space:]]|$) ]] || \
   [[ $command =~ ^find([[:space:]]|$) ]] || \
   [[ $command =~ ^cat([[:space:]]|$) ]] || \
   [[ $command =~ ^head([[:space:]]|$) ]] || \
   [[ $command =~ ^tail([[:space:]]|$) ]] || \
   [[ $command =~ ^wc([[:space:]]|$) ]] || \
   [[ $command =~ ^git([[:space:]]|$) ]] || \
   [[ $command =~ ^echo([[:space:]]|$) ]] || \
   [[ $command =~ ^pwd$ ]] || \
   [[ $command =~ ^which([[:space:]]|$) ]] || \
   [[ $command =~ ^file([[:space:]]|$) ]] || \
   [[ $command =~ ^stat([[:space:]]|$) ]] || \
   [[ $command =~ ^du([[:space:]]|$) ]] || \
   [[ $command =~ ^df([[:space:]]|$) ]] || \
   [[ $command =~ ^uname ]] || \
   [[ $command =~ ^env$ ]] || \
   [[ $command =~ ^printenv ]] || \
   [[ $command =~ ^npm([[:space:]]|$) ]] || \
   [[ $command =~ ^yarn([[:space:]]|$) ]] || \
   [[ $command =~ ^pnpm([[:space:]]|$) ]] || \
   [[ $command =~ ^node([[:space:]]|$) ]] || \
   [[ $command =~ ^python3?([[:space:]]|$) ]] || \
   [[ $command =~ ^pip([[:space:]]|$) ]] || \
   [[ $command =~ ^grep([[:space:]]|$) ]] || \
   [[ $command =~ ^sort([[:space:]]|$) ]] || \
   [[ $command =~ ^uniq([[:space:]]|$) ]] || \
   [[ $command =~ ^cut([[:space:]]|$) ]] || \
   [[ $command =~ ^tr([[:space:]]|$) ]] || \
   [[ $command =~ ^diff([[:space:]]|$) ]] || \
   [[ $command =~ ^jq([[:space:]]|$) ]] || \
   [[ $command =~ ^date([[:space:]]|$) ]] || \
   [[ $command =~ ^hostname$ ]] || \
   [[ $command =~ ^whoami$ ]] || \
   [[ $command =~ ^id([[:space:]]|$) ]] || \
   [[ $command =~ ^basename([[:space:]]|$) ]] || \
   [[ $command =~ ^dirname([[:space:]]|$) ]] || \
   [[ $command =~ ^realpath([[:space:]]|$) ]] || \
   [[ $command =~ ^tree([[:space:]]|$) ]] || \
   [[ $command =~ ^less([[:space:]]|$) ]] || \
   [[ $command =~ ^more([[:space:]]|$) ]] || \
   [[ $command =~ ^mkdir([[:space:]]|$) ]] || \
   [[ $command =~ ^touch([[:space:]]|$) ]] || \
   [[ $command =~ ^mv([[:space:]]|$) ]] || \
   [[ $command =~ ^cp([[:space:]]|$) ]] || \
   [[ $command =~ ^rm([[:space:]]|$) ]] || \
   [[ $command =~ ^\.\/.+ ]]; then
  echo "DEBUG: MATCH! Allowing command" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Safe command auto-approved"}}'
  exit 0
fi

# Sinon, prompt standard
echo "DEBUG: NO MATCH. Prompting user" >> /tmp/claude-hook-debug.log
exit 1
