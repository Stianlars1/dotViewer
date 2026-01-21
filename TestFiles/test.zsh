#!/usr/bin/env zsh
# Sample zsh script for E2E testing

autoload -Uz colors && colors

# Configuration
typeset -A config
config[app_name]="dotViewer"
config[version]="1.1.0"

# Function with zsh-specific features
function print_status() {
    local status=$1
    local message=$2

    if [[ $status == "ok" ]]; then
        print -P "%F{green}✓%f $message"
    else
        print -P "%F{red}✗%f $message"
    fi
}

# Array operations
extensions=(.swift .js .ts .py .go .rs)
for ext in $extensions; do
    print_status "ok" "Testing $ext files"
done
