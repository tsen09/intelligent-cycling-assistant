#!/usr/bin/env bash

# ==========================================
# APPLICATION CONFIGURATION
# ==========================================

export APP_NAME="Miguel"
export APP_DEBUG=true
export APP_HOST="127.0.0.1"
export APP_PORT=8001

# ==========================================
# DATABASE CONFIGURATION
# ==========================================

export DB_DRIVER="postgresql"
export DB_HOST="localhost"
export DB_PORT=5432
export DB_NAME="miguel-test"
export DB_POOL_SIZE=2
export DB_MAX_OVERFLOW=2

# ==========================================
# PYTHON CONFIGURATION
# ==========================================

export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1