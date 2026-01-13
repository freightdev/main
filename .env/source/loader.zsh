#############################
# ZBOX Master Source Loader
#############################
CORE_DIR="${0:A:h}"
default_exts=(zsh sh lua)

# -------------------------
# Default directories
# -------------------------
typeset -a default_dirs=(
  agents
  defaults
  functions
  # helpers
  settings
  # setups
)

# -------------------------
# Decide load mode
# -------------------------
if (( ${+src_dirs} )); then
  load_specs=("${src_dirs[@]}")
else
  load_specs=("${default_dirs[@]}")
fi

# -------------------------
# Loader core
# -------------------------
for spec in "${load_specs[@]}"; do
  # Parse spec: dir or dir::exts::targets
  parts=("${(@s/::/)spec}")
  dir="${parts[1]}"
  exts="${parts[2]:-}"
  targets="${parts[3]:-}"
  
  base="$CORE_DIR/$dir"
  [[ -d "$base" ]] || continue

  # -------------------------
  # Determine extensions
  # -------------------------
  if [[ -z "$exts" ]]; then
    # No exts specified: use defaults (zsh, sh, lua)
    ext_list=("${default_exts[@]}")
  elif [[ "$exts" == "*" ]]; then
    # Wildcard: load ALL extensions
    ext_list=("*")
  else
    # Specific extension(s)
    ext_list=("$exts")
  fi

  # -------------------------
  # Determine targets
  # -------------------------
  if [[ -z "$targets" ]]; then
    # No targets specified: load ALL files in directory with default extensions
    target_list=("*")
  elif [[ "$targets" == "*" ]]; then
    # Wildcard: load everything in the directory
    target_list=("*")
  else
    # Specific target file(s)
    target_list=("$targets")
  fi

  # -------------------------
  # Resolve and source files
  # -------------------------
  for tgt in "${target_list[@]}"; do
    if [[ "$tgt" == "*" ]]; then
      # Load all files with specified extensions
      for ext in "${ext_list[@]}"; do
        if [[ "$ext" == "*" ]]; then
          # Load everything regardless of extension
          for f in "$base"/*(.N); do
            source "$f"
          done
        else
          # Load files with specific extension
          for f in "$base"/*."$ext"(.N); do
            source "$f"
          done
        fi
      done
    else
      # Load specific file(s)
      for ext in "${ext_list[@]}"; do
        if [[ "$ext" == "*" ]]; then
          # Try loading with any extension
          for f in "$base/$tgt".*(N); do
            [[ -f "$f" ]] && source "$f"
          done
        else
          # Load with specific extension
          f="$base/$tgt.$ext"
          [[ -f "$f" ]] && source "$f"
        fi
      done
    fi
  done
done

#############################
# Symlink Management
#############################
create_symlink() {
  local source="$1"
  local target="$2"
  mkdir -p "${target:h}"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return 0
  fi
  [[ -e "$target" || -L "$target" ]] && rm -rf "$target"
  ln -sf "$source" "$target"
}

# Dotfiles → ~/
if [[ -d "$ZBOX_CFG/dotfiles" ]]; then
  for file in "$ZBOX_CFG/dotfiles"/.[^.]*; do
    [[ -e "$file" ]] || continue
    create_symlink "$file" "$HOME/${file:t}"
  done
fi

# Dotdirs → ~/.config/
if [[ -d "$ZBOX_CFG/dotdirs" ]]; then
  for item in "$ZBOX_CFG/dotdirs"/*; do
    [[ -e "$item" ]] || continue
    create_symlink "$item" "$HOME/.config/${item:t}"
  done
fi
