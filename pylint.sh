#!/bin/bash
set -euxo pipefail  

APP_DIR="/home/ubuntu/todo-app"
PYTHON_BIN="/usr/bin/python3"
PYLINT_LOG="pylint_report.log"

cd "$APP_DIR"

$PYTHON_BIN -m pip install --upgrade pip pylint

$PYTHON_BIN -m pylint $(find . -name "*.py") | tee "$PYLINT_LOG"

if grep -q "error" "$PYLINT_LOG"; then
    exit 1
fi
