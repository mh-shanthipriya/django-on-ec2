#!/bin/bash
set -euxo pipefail  

APP_DIR="/home/ubuntu/todo-app"
VENV_DIR="$APP_DIR/venv"
PYLINT_LOG="pylint_report.log"

cd "$APP_DIR"

# Create and activate virtual environment if not exists
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Ensure pip and pylint are installed
pip install --upgrade pip pylint

# Run pylint on all Python files and save the output
pylint $(find . -name "*.py") | tee "$PYLINT_LOG"

# Deactivate virtual environment
deactivate

# Exit with error code if pylint finds errors
if grep -q "error" "$PYLINT_LOG"; then
    exit 1
fi
