#!/bin/bash
# Enforce strict error handling
set -euxo pipefail  

# Define variables
APP_DIR="/home/ubuntu/jenkins/jenkins/workspace/get_deploy_develop/todoApp"
PYTHON_BIN="/usr/bin/python3"

# Navigate to the application directory
cd "$APP_DIR" || { echo "❌ ERROR: Directory $APP_DIR not found!"; exit 1; }

# Run Pylint checks
echo "🔍 Running Pylint Checks..."
$PYTHON_BIN -m pylint todoApp todos manage.py | tee pylint.log || echo "⚠️ Pylint warnings found, review pylint.log."

# Start the application
echo "🚀 Starting Django Application..."
nohup $PYTHON_BIN manage.py runserver 0.0.0.0:8000 > app.log 2>&1 &

echo "✅ Deployment successful!"
