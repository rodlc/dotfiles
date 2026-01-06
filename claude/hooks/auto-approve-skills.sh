#!/bin/bash
# Auto-approve specific skills to avoid permission prompts
# Used by PermissionRequest hook in settings.json

input=$(cat)
skill_name=$(echo "$input" | jq -r '.tool_input.skill // empty')

# Debug logging (optional, comment out if not needed)
# echo "DEBUG: PermissionRequest for skill='$skill_name'" >> /tmp/claude-hook-debug.log

# Auto-approve specific skills
if echo "$skill_name" | grep -qE "^(memorize|wrap|notion|summarize|terminal-title)$"; then
  echo '{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "allow"}}}'
  exit 0
fi

# Otherwise, proceed normally (ask for permission)
exit 0
