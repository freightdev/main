#!/bin/zsh
#############################
# ZBOX Profile Initialization
#############################

##################
#  PATH CONFIGS
##################

# Add custom paths
typeset -U path
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    $path
)
export PATH

## Add custom user overrides below
## These will persist across ZBOX updates
