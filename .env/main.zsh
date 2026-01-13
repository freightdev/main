######################
# ZBOX_ENV Environment
######################

# ===================================
# STEP 1: BOOTSTRAP BASE PATHS
# ===================================
: "${ZBOX_ENV:=${0:A:h}}"
: "${ZBOX_CFG:=$ZBOX_ENV/config}"
: "${ZBOX_SRC:=$ZBOX_ENV/source}"

# ===================================
# STEP 2: CONDITIONAL LOADING
# ===================================
if [[ -f "${ZBOX_SRC}/loader.zsh" ]]; then
    . "${ZBOX_SRC}/loader.zsh"
else
    echo "ERROR: Config loader not found at ${ZBOX_SRC}/loader.zsh" >&2
    return 1
fi
