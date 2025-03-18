#!/bin/bash
set -euxo pipefail

# Set the correct app directory
APP_DIR="/home/ubuntu/todoApp"
VENV_DIR="$APP_DIR/venv"
PYLINT_LOG="pylint_report.log"

# Navigate to the app directory
cd "$APP_DIR"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then  
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Upgrade pip and install dependencies
pip install --upgrade pip pylint pylint-django
pip install -r requirements.txt || exit 1

# Add APP_DIR to PYTHONPATH for proper import resolution
export PYTHONPATH=$APP_DIR

# Find Python files excluding venv
PYTHON_FILES=$(find "$APP_DIR" -type f -name "*.py" ! -path "$APP_DIR/venv/*")

if [ -z "$PYTHON_FILES" ]; then
    echo "No Python files found for linting."
    exit 0
fi

# Run pylint with customized rules
pylint \
    --disable=E0307,E1101,C0103,C0415,C0411,C0304,C0114,C0115,C0116,C0301,C0303,W0611,W0613 \
    $PYTHON_FILES | tee "$PYLINT_LOG"

# Deactivate virtual environment
deactivate

# Exit with error code only for severe issues (Errors or Fatal)
if grep -qE "(E|fatal)" "$PYLINT_LOG"; then
    echo "❌ Pylint found critical errors. Check $PYLINT_LOG for details."
    exit 1
fi

echo "✅ Pylint checks passed successfully!"
exit 0
