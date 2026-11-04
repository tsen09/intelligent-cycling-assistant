#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================================
# Miguel - Intelligent Cycling Assistant
# Main CLI Entry Point
# ============================================================================

# ----------------------------------------------------------------------------
# Project Paths
# ----------------------------------------------------------------------------

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

SETUP_SCRIPT="$SCRIPTS_DIR/setup.sh"
RUN_SCRIPT="$SCRIPTS_DIR/run.sh"

# ----------------------------------------------------------------------------
# Shared Terminal Utilities
# ----------------------------------------------------------------------------

source "$SCRIPTS_DIR/lib/common.sh"

# ============================================================================
# Help
# ============================================================================

show_help() {
    print_banner

    printf '%bUSAGE%b\n' "$BOLD" "$RESET"
    printf '  ./miguel.sh <command> [options]\n\n'

    printf '%bCOMMANDS%b\n' "$BOLD" "$RESET"
    printf '  %bsetup%b       Set up the project environment\n' "$CYAN" "$RESET"
    printf '  %brun%b         Start Miguel\n' "$CYAN" "$RESET"
    printf '  %bhelp%b        Display this help message\n\n' "$CYAN" "$RESET"

    printf '%bOPTIONS%b\n' "$BOLD" "$RESET"
    printf '  %b-h, --help%b      Display help\n' "$CYAN" "$RESET"
    printf '  %b-v, --version%b   Display version information\n\n' "$CYAN" "$RESET"

    printf '%bEXAMPLES%b\n' "$BOLD" "$RESET"
    printf '  ./miguel.sh setup\n'
    printf '  ./miguel.sh run\n'
    printf '  ./miguel.sh run --mode production\n\n'

    printf '%bMiguel | Open-source cycling assistant | MIT License%b\n\n' \
        "$DIM" "$RESET"
}

# ============================================================================
# Command Execution
# ============================================================================

execute_script() {
    local script_path="$1"
    local script_name="$2"

    shift 2

    if [[ ! -f "$script_path" ]]; then
        log_error "Script not found: $script_path"
        exit 1
    fi

    log_info "$script_name"

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
            execute_script "$SETUP_SCRIPT" "Preparing Miguel..." "$@"
            ;;

        run)
            shift
            execute_script "$RUN_SCRIPT" "Launching Miguel..." "$@"
            ;;

        help|--help|-h)
            show_help
            ;;

        --version|-v)
            print_banner

            if [[ ! -f "$PROJECT_ROOT/pyproject.toml" ]]; then
                log_error "pyproject.toml not found."
                exit 1
            fi

            if ! command -v python3 &>/dev/null; then
                log_error "Python 3 is required to read the project version."
                exit 1
            fi

            VERSION="$(python3 -c '
import sys
import tomllib

with open(sys.argv[1], "rb") as f:
    print(tomllib.load(f)["project"]["version"])
' "$PROJECT_ROOT/pyproject.toml")"

            printf '  %bMiguel v%s%b\n\n' "$BOLD" "$VERSION" "$RESET"
            ;;

        *)
            print_banner

            log_error "Unknown command: $command"

            printf '\n'
            show_help

            exit 1
            ;;

    esac
}

main "$@"
