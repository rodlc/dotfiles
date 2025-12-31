#!/bin/bash
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Debug: log pour troubleshooting
echo "DEBUG: command='$command'" >> /tmp/claude-hook-debug.log

# DENY: Git destructif (vérifier AVANT les allows)
if [[ $command =~ git.*reset.*--hard ]] || \
   [[ $command =~ git.*push.*(-f|--force) ]] || \
   [[ $command =~ git.*checkout.*--[[:space:]] ]] || \
   [[ $command =~ git.*clean.*-f ]] || \
   [[ $command =~ git.*branch.*-D ]]; then
  echo "DEBUG: DENY! Destructive git command" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Destructive git command blocked for safety"}}'
  exit 0
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
   [[ $command =~ ^more([[:space:]]|$) ]]; then
  echo "DEBUG: MATCH! Allowing command" >> /tmp/claude-hook-debug.log
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Safe command auto-approved"}}'
  exit 0
fi

# Sinon, prompt standard
echo "DEBUG: NO MATCH. Prompting user" >> /tmp/claude-hook-debug.log
exit 1
