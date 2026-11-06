#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================================
# Miguel - Intelligent Cycling Assistant
# Uninstallation Script
# ============================================================================

# ----------------------------------------------------------------------------
# Project Paths
# ----------------------------------------------------------------------------

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# ----------------------------------------------------------------------------
# Shared Terminal Utilities
# ----------------------------------------------------------------------------

source "$SCRIPTS_DIR/lib/common.sh"

# ============================================================================
# Configuration
# ============================================================================

AUTO_CONFIRM=false

# ============================================================================
# Help
# ============================================================================

show_help() {
    print_banner

    printf '%bUSAGE%b\n' "$BOLD" "$RESET"
    printf '  ./miguel.sh --remove [options]\n\n'

    printf '%bOPTIONS%b\n' "$BOLD" "$RESET"
    printf '  %b-y, --yes%b    Skip confirmation prompts\n' "$CYAN" "$RESET"
    printf '  %b-h, --help%b   Display this help message\n\n' "$CYAN" "$RESET"
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;

            -h|--help)
                show_help
                exit 0
                ;;

            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Confirmation
# ============================================================================

confirm_uninstallation() {
    if [[ "$AUTO_CONFIRM" == true ]]; then
        return 0
    fi

    printf '\n'
    printf '%bWARNING%b\n' "$YELLOW" "$RESET"
    printf '  This will remove Miguel'\''s local Python environment\n'
    printf '  and generated build/cache artifacts.\n\n'

    printf '  Your source code, Git history, documentation,\n'
    printf '  and shared system dependencies will be preserved.\n\n'

    if [[ ! -t 0 ]]; then
        log_error "Interactive confirmation required. Use --yes to proceed."
        exit 1
    fi

    read -r -p "  Are you sure you want to continue? [y/N]: " response

    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;

        *)
            log_info "Uninstallation cancelled."
            exit 0
            ;;
    esac
}

# ============================================================================
# Cleanup
# ============================================================================

remove_directory() {
    local target="$1"

    if [[ -d "$target" || -L "$target" ]]; then
        rm -rf -- "$target"
        log_info "Removed: ${target#"$PROJECT_ROOT"/}"
    fi
}

remove_generated_artifacts() {
    local target

    # Remove the Python virtual environment.
    remove_directory "$PROJECT_ROOT/.venv"

    # Remove common project-level caches and build artifacts.
    for target in \
        "$PROJECT_ROOT/__pycache__" \
        "$PROJECT_ROOT/.pytest_cache" \
        "$PROJECT_ROOT/.ruff_cache" \
        "$PROJECT_ROOT/.mypy_cache" \
        "$PROJECT_ROOT/.cache" \
        "$PROJECT_ROOT/build" \
        "$PROJECT_ROOT/dist"
    do
        remove_directory "$target"
    done

    # Remove nested Python caches and generated package metadata.
    find "$PROJECT_ROOT" \
        -type d \( \
            -name .git -o \
            -name .venv -o \
            -name .idea -o \
            -name .github \
        \) -prune -o \
        -type d \( \
            -name __pycache__ -o \
            -name .pytest_cache -o \
            -name .ruff_cache -o \
            -name .mypy_cache -o \
            -name '*.egg-info' \
        \) -prune -exec rm -rf -- {} +

    log_info "Removed generated Python artifacts."
}

# ============================================================================
# Main
# ============================================================================

main() {
    parse_arguments "$@"

    print_banner

    log_info "Preparing to uninstall Miguel..."

    confirm_uninstallation

    printf '\n'
    log_info "Removing Miguel environment..."

    remove_generated_artifacts

    printf '\n'
    log_info "Miguel environment successfully removed."
    printf '\n'

    printf '%bMiguel has been uninstalled.%b\n' "$BOLD" "$GREEN"
    printf '  Project source files and Git history remain intact.\n\n'
}

main "$@"
