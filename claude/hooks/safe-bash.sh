#!/bin/bash
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Debug: log pour troubleshooting
echo "DEBUG: command='$command'" >> /tmp/claude-hook-debug.log

# ════════════════════════════════════════════════════════════════════
# PROMPT INJECTION & EXFILTRATION PROTECTIONS
# ════════════════════════════════════════════════════════════════════

# Limite taille commande (prévient payload injection)
if [[ ${#command} -gt 4096 ]]; then
  echo "DEBUG: DENY! Command too long (${#command} chars)" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Command exceeds 4096 char limit"}}'
  exit 0
fi

# Encodage/obfuscation suspects (base64, hex, xxd)
if [[ $command =~ base64[[:space:]]+-d ]] || \
   [[ $command =~ \|[[:space:]]*base64 ]] || \
   [[ $command =~ xxd[[:space:]]+-r ]] || \
   [[ $command =~ printf[[:space:]].*\\\\x ]]; then
  echo "DEBUG: DENY! Encoding/obfuscation detected" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Encoding/obfuscation pattern blocked"}}'
  exit 0
fi

# Exécution dynamique (eval, exec, source avec variables)
if [[ $command =~ (eval|exec|source|\\.)[[:space:]]+(.*\$|\`|\".*\$|\'\$) ]]; then
  echo "DEBUG: DENY! Dynamic execution detected" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Dynamic eval/exec/source blocked"}}'
  exit 0
fi

# Network exfiltration (curl/wget POST, nc, reverse shells)
# Exception: localhost/127.0.0.1 autorisé (MCP memory-service, etc.)
is_localhost=false
if [[ $command =~ http://(localhost|127\.0\.0\.1) ]]; then
  is_localhost=true
fi

if [[ $is_localhost == false ]] && \
   { [[ $command =~ curl[[:space:]].*(-X[[:space:]]*POST|--data|-d[[:space:]]) ]] || \
     [[ $command =~ curl[[:space:]].*-T ]] || \
     [[ $command =~ wget[[:space:]].*--post ]] ; }; then
  echo "DEBUG: DENY! Network exfiltration pattern detected" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Network exfiltration pattern blocked"}}'
  exit 0
fi

# nc/netcat et /dev/tcp toujours bloqués (pas de localhost exception)
if [[ $command =~ (nc|netcat|ncat)[[:space:]] ]] || \
   [[ $command =~ /dev/(tcp|udp)/ ]] || \
   [[ $command =~ \|[[:space:]]*(curl|wget|nc) ]]; then
  echo "DEBUG: DENY! Network exfiltration pattern detected" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Network exfiltration pattern blocked"}}'
  exit 0
fi

# Inline script execution (bash -c, python -c, node -e avec contenu suspect)
if [[ $command =~ (bash|sh|zsh)[[:space:]]+-c[[:space:]]+ ]] || \
   [[ $command =~ python[[:space:]]+-c[[:space:]]+ ]] || \
   [[ $command =~ node[[:space:]]+-e[[:space:]]+ ]]; then
  echo "DEBUG: DENY! Inline script execution detected" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Inline script execution blocked - use a file instead"}}'
  exit 0
fi

# SUDO: Prompt user to run manually
if [[ $command =~ ^sudo[[:space:]] ]]; then
  echo "DEBUG: SUDO - prompt user to run manually" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Run manually:\n\n    '"$command"'"}}'
  exit 0
fi

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

# DENY: Lecture fichiers sensibles
if [[ $command =~ (cat|head|tail|less|more|bat|strings)[[:space:]]+(.*/)?(\.env|\.env\.[^[:space:]]*|id_rsa|id_ed25519|.*\.pem|.*\.key|credentials\.yml\.enc|master\.key)([[:space:]]|$) ]] || \
   [[ $command =~ (cat|head|tail|less|more|bat|strings)[[:space:]]+.*/(\.(ssh|gnupg|aws|kube))/ ]]; then
  echo "DEBUG: DENY! Sensitive file read blocked" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Sensitive file access blocked for security"}}'
  exit 0
fi

# DENY: Commandes système destructives
if [[ $command =~ ^(dd|mkfs|fdisk|parted)[[:space:]] ]] || \
   [[ $command =~ ^chmod[[:space:]]+-R[[:space:]]+777 ]] || \
   [[ $command =~ ^chown[[:space:]]+-R ]]; then
  echo "DEBUG: DENY! Destructive system command" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Destructive system command blocked"}}'
  exit 0
fi

# Commandes safe (même avec pipes/redirections)
if [[ $command =~ ^cd([[:space:]]|$) ]] || \
   [[ $command =~ ^(magick|convert|exiftool|weasyprint)([[:space:]]|$) ]] || \
   [[ $command =~ ^(gh|code|open)([[:space:]]|$) ]] || \
   [[ $command =~ ^yt-dlp([[:space:]]|$) ]] || \
   [[ $command =~ ^command([[:space:]]|$) ]] || \
   [[ $command =~ ^ls([[:space:]]|$) ]] || \
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
   [[ $command =~ ^bundle([[:space:]]|$) ]] || \
   [[ $command =~ ^rake([[:space:]]|$) ]] || \
   [[ $command =~ ^rails([[:space:]]|$) ]] || \
   [[ $command =~ ^rspec([[:space:]]|$) ]] || \
   [[ $command =~ ^rubocop([[:space:]]|$) ]] || \
   [[ $command =~ ^make([[:space:]]|$) ]] || \
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
   [[ $command =~ ^curl[[:space:]].*http://(localhost|127\.0\.0\.1)(:|/) ]] || \
   [[ $command =~ ^\.\/.+ ]]; then
  echo "DEBUG: MATCH! Allowing command" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Safe command auto-approved"}}'
  exit 0
fi

# Sinon, prompt standard (exit 0 sans JSON selon doc officielle)
echo "DEBUG: NO MATCH. Prompting user" >> /tmp/claude-hook-debug.log
exit 0
