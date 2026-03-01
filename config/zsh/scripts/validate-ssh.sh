#!/bin/bash
# Validate SSH config references existing keys

config_file="$HOME/.ssh/config"
[[ ! -f "$config_file" ]] && exit 0

missing=()
while read -r key_path; do
    expanded="${key_path/#\~/$HOME}"
    [[ ! -f "$expanded" ]] && missing+=("$expanded")
done < <(grep "IdentityFile" "$config_file" | awk '{print $2}' | sort -u)

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "⚠️  SSH config references missing keys:"
    printf "   - %s\n" "${missing[@]}"
    echo "   → Rename existing keys or run: bw-pull"
fi
