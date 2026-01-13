#!/bin/zsh
###################################
# ZBOX Environment Initialization
# Loaded for ALL shell types
###################################

# Source the master environment loader
# This ensures ZBOX is available in interactive, login, and non-interactive shells
if [[ -f "/ws/.env/main.zsh" ]]; then
    . "/ws/.env/main.zsh"
fi

## Add custom user overrides below
## These will persist across ZBOX updates
