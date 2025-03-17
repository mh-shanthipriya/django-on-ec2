#!/bin/bash
set -euxo pipefail  

APP_DIR="/home/ubuntu/todo-app"
VENV_DIR="$APP_DIR/venv"
PYLINT_LOG="pylint_report.log"

cd "$APP_DIR"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Ensure pylint is installed
pip install --upgrade pip pylint

pylint $(find . -name "*.py" -not -path "./venv/*") | tee "$PYLINT_LOG"

deactivate

# Exit with error code if pylint finds errors
if grep -q "error" "$PYLINT_LOG"; then
    exit 1
fi
