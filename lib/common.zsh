backup() {
  local target="$1"
  [ -e "$target" ] && [ ! -L "$target" ] && mv "$target" "$target.backup" && echo "-----> Backed up $target" || true
}

symlink() {
  local source="$1" link="$2"
  [ ! -e "$source" ] && echo "Warning: $source not found" && return 0

  # If symlink exists but points elsewhere, recreate it
  if [ -L "$link" ]; then
    local current=$(readlink "$link")
    if [ "$current" != "$source" ]; then
      rm "$link"
      echo "-----> Fixed $link (was: $current)"
    fi
  fi

  [ ! -e "$link" ] && ln -s "$source" "$link" && echo "-----> Linked $link" || true
}

ensure_machine_role() {
  local role_file="$DOTFILES_ROLE_FILE"
  if [[ ! -f "$role_file" ]]; then
    read "is_ref?Is this the reference machine (scheduler, memory server, backups, WhatsApp)? [y/N] "
    mkdir -p "${role_file:h}"
    [[ "$is_ref" =~ ^[Yy]$ ]] && echo reference > "$role_file" || echo client > "$role_file"
  fi
}
