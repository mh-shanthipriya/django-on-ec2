#!/bin/bash
# Enforce strict error handling
set -euxo pipefail  

# Define variables
APP_DIR="/home/jenkins/workspace/git_deploy_develop"
PYTHON_BIN="/usr/bin/python3"

# Debugging: Check current directory and list files
echo "📂 Current Directory: $(pwd)"
echo "📝 Listing /home/jenkins/workspace/"
ls -la /home/jenkins/workspace/
echo "📝 Listing APP_DIR ($APP_DIR)"
ls -la "$APP_DIR" || echo "⚠️ APP_DIR not found!"

# Ensure the directory exists
if [ ! -d "$APP_DIR" ]; then
    echo "❌ ERROR: Directory $APP_DIR not found!"
    exit 1
fi

# Navigate to the application directory
cd "$APP_DIR"

# Ensure manage.py exists
if [ ! -f "manage.py" ]; then
    echo "❌ ERROR: manage.py not found in $APP_DIR!"
    exit 1
fi

# Activate virtual environment (if it exists)
if [ -d "venv" ]; then
    echo "✅ Activating Virtual Environment"
    source venv/bin/activate
else
    echo "⚠️ Virtual environment not found. Running without venv."
fi

# Run Pylint checks
echo "🔍 Running Pylint Checks..."
$PYTHON_BIN -m pylint todoApp todos manage.py | tee pylint.log || echo "⚠️ Pylint warnings found, review pylint.log."

# Start the application
echo "🚀 Starting Django Application..."
nohup $PYTHON_BIN manage.py runserver 0.0.0.0:8000 > app.log 2>&1 &

echo "✅ Deployment successful!"
