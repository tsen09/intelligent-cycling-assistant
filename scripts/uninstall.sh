
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
        log_warning "Confirmation skipped (--yes)."
        return 0
    fi

    printf '\n'
    printf '%bWARNING%b\n' "$YELLOW" "$RESET"
    printf '  This will remove Miguel'\''s local Python environment\n'
    printf '  and generated build/cache artifacts.\n\n'

    printf '  The following will be preserved:\n'
    printf '    - Source code and Git history\n'
    printf '    - Project configuration and documentation\n'
    printf '    - uv.lock and pyproject.toml\n'
    printf '    - System-wide uv and Python installations\n'
    printf '    - User-level dependencies and caches\n\n'

    if [[ ! -t 0 ]]; then
        log_error "Interactive confirmation required. Use --yes to proceed."
        exit 1
    fi

    read -r -p "  Are you sure you want to uninstall Miguel? [y/N]: " response || {
        log_warning "No confirmation received. Uninstallation cancelled."
        exit 0
    }

    case "$response" in
        [yY])
            log_success "Uninstallation confirmed."
            return 0
            ;;

        [nN]|"")
            log_info "Uninstallation cancelled."
            exit 0
            ;;

        *)
            log_warning "Invalid response. Please enter y or n."
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
        if rm -rf -- "$target"; then
            log_success "Removed: ${target#"$PROJECT_ROOT"/}"
        else
            log_error "Failed to remove: ${target#"$PROJECT_ROOT"/}"
            return 1
        fi
    fi
}

remove_generated_artifacts() {
    local target

    # ------------------------------------------------------------------------
    # Remove the Python virtual environment.
    # ------------------------------------------------------------------------

    remove_directory "$PROJECT_ROOT/.venv"

    # ------------------------------------------------------------------------
    # Remove common project-level caches and build artifacts.
    # ------------------------------------------------------------------------

    for target in \
        "$PROJECT_ROOT/__pycache__" \
        "$PROJECT_ROOT/.pytest_cache" \
        "$PROJECT_ROOT/.ruff_cache" \
        "$PROJECT_ROOT/.mypy_cache" \
        "$PROJECT_ROOT/build" \
        "$PROJECT_ROOT/dist"
    do
        remove_directory "$target"
    done

    # ------------------------------------------------------------------------
    # Remove nested Python caches and generated package metadata.
    # Preserve Git, IDE configuration, and nested virtual environments.
    # ------------------------------------------------------------------------

    if ! find "$PROJECT_ROOT" \
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
        \) -prune -exec rm -rf -- {} +; then

        log_error "Failed to clean generated Python artifacts."
        return 1
    fi

    log_success "Generated Python artifacts cleaned."
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
    print_section "Removing Miguel environment"

    remove_generated_artifacts

    printf '\n'
    log_success "Miguel environment successfully removed."
    printf '\n'

    printf '%bMiguel has been uninstalled.%b\n' "$BOLD" "$GREEN"
    printf '  Project source files and Git history remain intact.\n'
    printf '  Run ./miguel.sh setup whenever you want to reinstall.\n\n'
}

main "$@"
