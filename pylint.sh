#!/bin/bash
set -euxo pipefail

# Set the correct app directory
APP_DIR="/home/ubuntu/jenkins/jenkins/workspace/git_deploy_develop/todoApp"
VENV_DIR="$APP_DIR/venv"
PYLINT_LOG="pylint_report.log"

# Navigate to the app directory
cd "$APP_DIR"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then  
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Upgrade pip and install pylint if not present
pip install --upgrade pip pylint

# Find Python files excluding venv
PYTHON_FILES=$(find "$APP_DIR" -type f -name "*.py" ! -path "$APP_DIR/venv/*")

if [ -z "$PYTHON_FILES" ]; then
    echo "No Python files found for linting."
    exit 0
fi

# Run pylint and save the report
pylint $PYTHON_FILES | tee "$PYLINT_LOG"

# Deactivate virtual environment
deactivate

# Exit with error code if pylint finds errors
if grep -q "error" "$PYLINT_LOG"; then
    echo "Pylint found errors, check $PYLINT_LOG"
    exit 1
fi
