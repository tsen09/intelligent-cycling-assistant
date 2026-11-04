#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================================
# Miguel - Intelligent Cycling Assistant
# Main CLI Entry Point
# ============================================================================

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

SETUP_SCRIPT="$SCRIPTS_DIR/setup.sh"
RUN_SCRIPT="$SCRIPTS_DIR/run.sh"

# ============================================================================
# Terminal Colors
# ============================================================================

if [[ -t 1 ]]; then
    RESET=$'\033[0m'
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    GREEN=$'\033[0;32m'
    CYAN=$'\033[0;36m'
    YELLOW=$'\033[0;33m'
    RED=$'\033[0;31m'
else
    RESET=''
    BOLD=''
    DIM=''
    GREEN=''
    CYAN=''
    YELLOW=''
    RED=''
fi

# ============================================================================
# Display
# ============================================================================

show_banner() {
    printf '\n'
    printf '%s' "${GREEN}${BOLD}"

    cat <<'EOF'
 __  __ ___ ____ _   _ _____ _
|  \/  |_ _/ ___| | | | ____| |
| |\/| || | |  _| | | |  _| | |
| |  | || | |_| | |_| | |___| |___
|_|  |_|___\____|\___/|_____|_____|
EOF

    printf '%s' "${RESET}"
    printf '  %sIntelligent Cycling Assistant%s\n' "${DIM}" "${RESET}"
    printf '  %sYour Cycling Companion to fuel Your Passion.%s\n' "${DIM}" "${RESET}"
    printf '\n'
}

# ============================================================================
# Help
# ============================================================================

show_help() {
    show_banner

    printf '%sUSAGE%s\n' "${BOLD}" "${RESET}"
    printf '  ./miguel.sh <command> [options]\n\n'

    printf '%sCOMMANDS%s\n' "${BOLD}" "${RESET}"
    printf '  %ssetup%s       Set up the project environment\n' "${CYAN}" "${RESET}"
    printf '  %srun%s         Start Miguel\n' "${CYAN}" "${RESET}"
    printf '  %shelp%s        Display this help message\n\n' "${CYAN}" "${RESET}"

    printf '%sOPTIONS%s\n' "${BOLD}" "${RESET}"
    printf '  %s-h, --help%s      Display help\n' "${CYAN}" "${RESET}"
    printf '  %s-v, --version%s   Display version information\n\n' "${CYAN}" "${RESET}"

    printf '%sEXAMPLES%s\n' "${BOLD}" "${RESET}"
    printf '  ./miguel.sh setup\n'
    printf '  ./miguel.sh run\n'
    printf '  ./miguel.sh run --mode production\n\n'

    printf '%sMiguel | Open-source cycling assistant | MIT License%s\n\n' \
        "${DIM}" "${RESET}"
}

# ============================================================================
# Command Execution
# ============================================================================

execute_script() {
    local script_path="$1"
    local script_name="$2"
    shift 2

    if [[ ! -f "$script_path" ]]; then
        printf '%s[ERROR]%s Script not found: %s\n' \
            "${RED}" "${RESET}" "$script_path" >&2
        exit 1
    fi

    printf '%s[INFO]%s %s\n\n' "${GREEN}" "${RESET}" "$script_name"

    exec bash "$script_path" "$@"
}

# ============================================================================
# Main
# ============================================================================

main() {
    local command="${1:-help}"

    case "$command" in

        setup)
            shift
            show_banner
            execute_script "$SETUP_SCRIPT" "Preparing Miguel..." "$@"
            ;;

        run)
            shift
            show_banner
            execute_script "$RUN_SCRIPT" "Launching Miguel..." "$@"
            ;;

        help|--help|-h)
            show_help
            ;;

        --version|-v)
            show_banner

            VERSION=$(python3 -c "
import tomllib
with open('$PROJECT_ROOT/pyproject.toml', 'rb') as f:
    print(tomllib.load(f)['project']['version'])
")

            printf '  %sMiguel v%s%s\n\n' "${BOLD}" "$VERSION" "${RESET}"
            ;;

        *)
            show_banner
            printf '%s[ERROR]%s Unknown command: %s\n\n' \
                "${RED}" "${RESET}" "$command" >&2
            show_help
            exit 1
            ;;

    esac
}

main "$@"
