# Per-project env-var mappings via chpwd hook

chpwd_traxyo_creds() {
  if [[ "$PWD" == */Code/rodlc/traxyo* || "$PWD" == */Code/rodlcmagic/traxyo* ]]; then
    [[ -n "$TRAXYO_RAILS_KEY" ]] && export RAILS_MASTER_KEY="$TRAXYO_RAILS_KEY"
  else
    [[ "$RAILS_MASTER_KEY" == "$TRAXYO_RAILS_KEY" ]] && unset RAILS_MASTER_KEY
  fi
}

chpwd_functions+=(chpwd_traxyo_creds)
chpwd_traxyo_creds

chpwd_posthog_creds() {
  if [[ "$PWD" == */Code/rodlcmagic/submagic* ]]; then
    [[ -n "$POSTHOG_SUBMAGIC_KEY" ]] && export POSTHOG_CLI_API_KEY="$POSTHOG_SUBMAGIC_KEY"
    export POSTHOG_CLI_PROJECT_ID=48392
  else
    [[ "$POSTHOG_CLI_API_KEY" == "$POSTHOG_SUBMAGIC_KEY" ]] && unset POSTHOG_CLI_API_KEY
    unset POSTHOG_CLI_PROJECT_ID
  fi
}

chpwd_functions+=(chpwd_posthog_creds)
chpwd_posthog_creds
