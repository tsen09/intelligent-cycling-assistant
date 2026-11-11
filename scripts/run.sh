#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================================
# Miguel - Intelligent Cycling Assistant
# Application Startup Script
# ============================================================================

# ----------------------------------------------------------------------------
# Project Paths
# ----------------------------------------------------------------------------

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

SCRIPTS_DIR="$PROJECT_ROOT/scripts"
CONFIG_DIR="$PROJECT_ROOT/backend/config"

ENV_FILE="$PROJECT_ROOT/.env"
SETUP_SCRIPT="$SCRIPTS_DIR/setup.sh"

VENV_DIR="$PROJECT_ROOT/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"

# ----------------------------------------------------------------------------
# Shared Terminal Utilities
# ----------------------------------------------------------------------------

source "$SCRIPTS_DIR/lib/common.sh"

# ============================================================================
# Configuration Loading
# ============================================================================

load_configuration() {

    # ------------------------------------------------------------------------
    # Load Environment Variables
    # ------------------------------------------------------------------------

    if [[ ! -f "$ENV_FILE" ]]; then
        log_error ".env file not found: $ENV_FILE"
        log_error "Create one using .env.example in the project root."
        exit 1
    fi

    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a

    # ------------------------------------------------------------------------
    # Validate Environment
    # ------------------------------------------------------------------------

    if [[ -z "${ENV:-}" ]]; then
        log_error "ENV is not defined in .env."
        exit 1
    fi

    case "$ENV" in
        development|testing|production)
            SETTINGS_FILE="$CONFIG_DIR/${ENV}.sh"
            ;;
        *)
            log_error "Invalid environment: $ENV"
            log_error "Allowed environments: development, testing, production"
            exit 1
            ;;
    esac

    # ------------------------------------------------------------------------
    # Load Environment-Specific Settings
    # ------------------------------------------------------------------------

    if [[ ! -f "$SETTINGS_FILE" ]]; then
        log_error "Configuration file not found: $SETTINGS_FILE"
        exit 1
    fi

    set -a
    # shellcheck disable=SC1090
    source "$SETTINGS_FILE"
    set +a

    # ------------------------------------------------------------------------
    # Application Defaults
    # ------------------------------------------------------------------------

    APP_MODULE="${MIGUEL_APP_MODULE:-src.main:app}"
    HOST="${MIGUEL_HOST:-127.0.0.1}"
    PORT="${MIGUEL_PORT:-8000}"
}

# ============================================================================
# Environment Validation
# ============================================================================

is_setup_complete() {
    [[ -x "$VENV_PYTHON" ]] &&
        "$VENV_PYTHON" -c "import uvicorn" &>/dev/null
}

# ============================================================================
# Setup Confirmation
# ============================================================================

confirm_setup() {

    printf '\n'
    printf '%bSETUP REQUIRED%b\n' "$YELLOW" "$RESET"
    printf '  Miguel has not been set up yet.\n'
    printf '  You need to configure the project environment before launching it.\n\n'

    if [[ ! -t 0 ]]; then
        log_error "Setup required. Run './miguel.sh setup' first."
        exit 1
    fi

    read -r -p "  Would you like to set up Miguel now? [y/N]: " response

    case "$response" in
        [yY]|[yY][eE][sS])
            printf '\n'
            log_info "Starting Miguel setup..."
            ;;

        *)
            printf '\n'
            log_info "Startup cancelled. Run './miguel.sh setup' when ready."
            exit 0
            ;;
    esac
}

# ============================================================================
# Environment Setup
# ============================================================================

ensure_setup() {

    if is_setup_complete; then
        log_success "Project environment is ready."
        return 0
    fi

    confirm_setup

    if [[ ! -f "$SETUP_SCRIPT" ]]; then
        log_error "Setup script not found: $SETUP_SCRIPT"
        exit 1
    fi

    bash "$SETUP_SCRIPT"

    printf '\n'

    if ! is_setup_complete; then
        log_error "Miguel setup did not complete successfully."
        log_error "Please check the setup logs and try again."
        exit 1
    fi

    log_success "Project environment is ready."
}

# ============================================================================
# Application Startup
# ============================================================================

start_miguel() {

    if ! command -v uv &>/dev/null; then
        log_error "uv is required to run Miguel."
        exit 1
    fi

    printf '\n'
    log_info "Launching Miguel..."

    printf '\n'
    printf '%bAPPLICATION CONFIGURATION%b\n' "$BOLD" "$RESET"
    printf '  Application : Miguel\n'
    printf '  Environment : %s\n' "$ENV"
    printf '  Host        : %s\n' "$HOST"
    printf '  Port        : %s\n' "$PORT"
    printf '  Entry point : %s\n\n' "$APP_MODULE"

    cd "$PROJECT_ROOT/backend"

    exec uv run --project "$PROJECT_ROOT" --no-sync \
        python -m uvicorn \
        "$APP_MODULE" \
        --host "$HOST" \
        --port "$PORT" \
        --reload
}

# ============================================================================
# Main
# ============================================================================

main() {

    print_banner

    load_configuration

    if ! command -v uv &>/dev/null; then
        log_error "uv is not installed or not available in PATH."
        exit 1
    fi

    ensure_setup

    start_miguel
}

main "$@"
