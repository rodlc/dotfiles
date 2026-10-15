# Per-project env-var mappings via chpwd hook

chpwd_traxyo_creds() {
  if [[ "$PWD" == */Code/rodlc/traxyo* || "$PWD" == */Code/rodlcmagic/traxyo* ]]; then
    [[ -n "$TRAXYO_RAILS_KEY" ]] && export RAILS_MASTER_KEY="$TRAXYO_RAILS_KEY"
    [[ -n "$POSTMARK_RODXYO_KEY" ]] && export POSTMARK_SERVER_TOKEN="$POSTMARK_RODXYO_KEY"
  else
    [[ "$RAILS_MASTER_KEY" == "$TRAXYO_RAILS_KEY" ]] && unset RAILS_MASTER_KEY
    [[ "$POSTMARK_SERVER_TOKEN" == "$POSTMARK_RODXYO_KEY" ]] && unset POSTMARK_SERVER_TOKEN
  fi
}

chpwd_functions+=(chpwd_traxyo_creds)
chpwd_traxyo_creds

chpwd_karkoi_creds() {
  if [[ "$PWD" == */Code/rodlc/karkoi* ]]; then
    [[ -n "$KARKOI_RAILS_KEY" ]] && export RAILS_MASTER_KEY="$KARKOI_RAILS_KEY"
  else
    [[ "$RAILS_MASTER_KEY" == "$KARKOI_RAILS_KEY" ]] && unset RAILS_MASTER_KEY
  fi
}

chpwd_functions+=(chpwd_karkoi_creds)
chpwd_karkoi_creds

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

chpwd_stripe_creds() {
  if [[ "$PWD" == */Code/rodlcmagic/submagic* ]]; then
    [[ -n "$STRIPE_SUBMAGIC_KEY" ]] && export STRIPE_API_KEY="$STRIPE_SUBMAGIC_KEY"
  else
    [[ "$STRIPE_API_KEY" == "$STRIPE_SUBMAGIC_KEY" ]] && unset STRIPE_API_KEY
  fi
}

chpwd_functions+=(chpwd_stripe_creds)
chpwd_stripe_creds

chpwd_greptile_creds() {
  if [[ "$PWD" == */Code/rodlc/traxyo* || "$PWD" == */Code/rodlc/karkoi* ]]; then
    [[ -n "$GREPTILE_RODOLPHE_KEY" ]] && export GREPTILE_API_KEY="$GREPTILE_RODOLPHE_KEY"
    # gh keychain token of rodlc, whatever account is active: replaces a long-lived PAT
    local token
    if [[ -z "$GITHUB_TOKEN_FROM_GH" ]] && token="$(gh auth token --user rodlc 2>/dev/null)"; then
      export GITHUB_TOKEN="$token" GITHUB_TOKEN_FROM_GH=1
    fi
  else
    [[ "$GREPTILE_API_KEY" == "$GREPTILE_RODOLPHE_KEY" ]] && unset GREPTILE_API_KEY
    [[ -n "$GITHUB_TOKEN_FROM_GH" ]] && unset GITHUB_TOKEN GITHUB_TOKEN_FROM_GH
  fi
}

chpwd_functions+=(chpwd_greptile_creds)
chpwd_greptile_creds
