######################
# ZBOX_ENV Environment
######################

# This prevents pollution in scripts and ensures correct behavior.
# Abort if not interactive
[[ -o interactive ]] || return

# Idempotency guard (prevents double load)
[[ -n ${__ZBOX_LOADED-} ]] && return
typeset -g __ZBOX_LOADED=1

# ===================================
# STEP 1: BOOTSTRAP BASE PATHS
# ===================================
: "${ZBOX_ENV:=${0:A:h}}"
: "${ZBOX_CFG:=$ZBOX_ENV}"
: "${ZBOX_SRC:=$ZBOX_ENV}"

# ===================================
# STEP 2: CONDITIONAL LOADING
# ===================================
if [[ -f "./loader.zsh" ]]; then
    . "./loader.zsh"
else
    echo "ERROR: Config loader not found at ${ZBOX_SRC}/loader.zsh" >&2
    return 1
fi
