#!/usr/bin/env bash

# ============================================================
# Miguel - Terminal Styling & Logging Utilities
# ============================================================

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

if [[ -t 1 ]]; then
    RESET='\033[0m'
    BOLD='\033[1m'
    DIM='\033[2m'

    BLACK='\033[0;30m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'

    BRIGHT_BLACK='\033[0;90m'
    BRIGHT_RED='\033[0;91m'
    BRIGHT_GREEN='\033[0;92m'
    BRIGHT_YELLOW='\033[0;93m'
    BRIGHT_BLUE='\033[0;94m'
    BRIGHT_MAGENTA='\033[0;95m'
    BRIGHT_CYAN='\033[0;96m'
    BRIGHT_WHITE='\033[0;97m'
else
    RESET=''
    BOLD=''
    DIM=''

    BLACK=''
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    WHITE=''

    BRIGHT_BLACK=''
    BRIGHT_RED=''
    BRIGHT_GREEN=''
    BRIGHT_YELLOW=''
    BRIGHT_BLUE=''
    BRIGHT_MAGENTA=''
    BRIGHT_CYAN=''
    BRIGHT_WHITE=''
fi

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

log_info() {
    printf '  %bℹ%b  %s\n' "$BLUE" "$RESET" "$*"
}

log_success() {
    printf '  %b✔%b  %s\n' "$GREEN" "$RESET" "$*"
}

log_warning() {
    printf '  %b⚠%b  %s\n' "$YELLOW" "$RESET" "$*"
}

log_error() {
    printf '  %b✖%b  %s\n' "$RED" "$RESET" "$*" >&2
}

log_step() {
    printf '\n  %b[%s]%b %b%s%b\n' \
        "$BOLD$CYAN" "$1" "$RESET" \
        "$WHITE" "$2" "$RESET"
}

# ------------------------------------------------------------
# Layout
# ------------------------------------------------------------

print_line() {
    printf '  %b────────────────────────────────────────────%b\n' \
        "$BRIGHT_BLACK" "$RESET"
}

print_banner() {
    printf '\n'

    printf '  %b  ███╗   ███╗██╗ ██████╗ ██╗   ██╗███████╗██╗%b\n' \
        "$BOLD$CYAN" "$RESET"
    printf '  %b  ████╗ ████║██║██╔════╝ ██║   ██║██╔════╝██║%b\n' \
        "$BOLD$CYAN" "$RESET"
    printf '  %b  ██╔████╔██║██║██║  ███╗██║   ██║█████╗  ██║%b\n' \
        "$BOLD$CYAN" "$RESET"
    printf '  %b  ██║╚██╔╝██║██║██║   ██║██║   ██║██╔══╝  ██║%b\n' \
        "$BOLD$CYAN" "$RESET"
    printf '  %b  ██║ ╚═╝ ██║██║╚██████╔╝╚██████╔╝███████╗███████╗%b\n' \
        "$BOLD$CYAN" "$RESET"
    printf '  %b  ╚═╝     ╚═╝╚═╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝%b\n' \
        "$BOLD$CYAN" "$RESET"

    printf '\n'
    printf '  %bConsider it handled. 🎩%b\n' "$DIM" "$RESET"

    print_line
}

print_section() {
    printf '\n'
    printf '  %b▸ %s%b\n' "$BOLD$WHITE" "$1" "$RESET"

    print_line
}

print_footer() {
    print_line

    printf '  %bMiguel | Consider it handled. 🎩%b\n\n' \
        "$DIM" "$RESET"
}
