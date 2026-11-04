#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# Miguel - Environment Setup
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/lib/common.sh"

cd "$PROJECT_ROOT"

PYTHON_VERSION="3.13"

# ============================================================
# Setup
# ============================================================

setup_environment() {

    print_banner

    printf '  %bEnvironment Setup%b\n' "$BOLD$WHITE" "$RESET"
    printf '  %bPreparing Miguel for development...%b\n' "$DIM" "$RESET"

    # --------------------------------------------------------
    # 1. Prerequisites
    # --------------------------------------------------------

    print_section "1. Checking prerequisites"

    if ! command -v uv &>/dev/null; then
        log_error "uv is not installed."
        log_info "Install: https://docs.astral.sh/uv/"
        return 1
    fi

    log_success "uv detected: $(uv --version)"

    # --------------------------------------------------------
    # 2. Project configuration
    # --------------------------------------------------------

    print_section "2. Validating project configuration"

    if [[ ! -f "$PROJECT_ROOT/pyproject.toml" ]]; then
        log_error "pyproject.toml not found."
        return 1
    fi

    log_success "Project configuration found."

    # --------------------------------------------------------
    # 3. Python installation
    # --------------------------------------------------------

    print_section "3. Preparing Python environment"

    log_info "Installing Python $PYTHON_VERSION if required..."

    uv python install "$PYTHON_VERSION"

    log_success "Python $PYTHON_VERSION is ready."

    # --------------------------------------------------------
    # 4. Dependencies
    # --------------------------------------------------------

    print_section "4. Installing dependencies"

    log_info "Synchronizing project dependencies..."

    uv sync --python "$PYTHON_VERSION" --group dev

    log_success "Dependencies installed successfully."

    # --------------------------------------------------------
    # 5. Verification
    # --------------------------------------------------------

    print_section "5. Verifying installation"

    PYTHON_VERSION_INSTALLED="$(uv run python --version)"

    log_success "Virtual environment: .venv"
    log_success "Runtime: $PYTHON_VERSION_INSTALLED"

    # --------------------------------------------------------
    # 6. Completion
    # --------------------------------------------------------

    printf '\n'
    print_line

    printf '  %b✔ MIGUEL IS READY!%b\n' "$BOLD$GREEN" "$RESET"
    printf '\n'

    printf '  %bYour development environment has been configured.%b\n' \
        "$WHITE" "$RESET"
    printf '\n'

    printf '  %bNext steps%b\n' "$BOLD$CYAN" "$RESET"
    printf '  %b────────────────────────────────────────────%b\n' \
        "$DIM" "$RESET"

    printf '  %b1.%b Configure environment variables in %b.env%b\n' \
        "$YELLOW" "$RESET" "$BOLD" "$RESET"

    printf '  %b2.%b Start Miguel using %b./miguel.sh run%b\n' \
        "$YELLOW" "$RESET" "$BOLD" "$RESET"

    printf '\n'

    print_footer
}

# ============================================================
# Main
# ============================================================

main() {
    setup_environment "$@"
}

main "$@"
