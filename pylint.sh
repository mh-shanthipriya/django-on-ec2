#!/bin/bash
# Enforce strict error handling
set -euxo pipefail  

# Use Jenkins' workspace environment variable
APP_DIR="${WORKSPACE:-/var/lib/jenkins/workspace/git_deploy_develop}"

# Debugging: Check the actual workspace path
echo "📂 Current Directory: $(pwd)"
echo "🔍 Expected APP_DIR: $APP_DIR"

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
    source "$APP_DIR/venv/bin/activate"
else
    echo "⚠️ Virtual environment not found. Running without venv."
fi

# Run Pylint checks
echo "🔍 Running Pylint Checks..."
python3 -m pylint todoApp todos manage.py | tee pylint.log
if [ $? -ne 0 ]; then
    echo "❌ Pylint checks failed. Fix issues before proceeding!"
    exit 1
fi

# Ensure no existing process is running on port 8000
echo "🔍 Checking for existing process on port 8000..."
fuser -k 8000/tcp || echo "⚠️ No existing process found on port 8000."

# Rotate logs
echo "🔄 Rotating logs..."
mv app.log app.log.bak 2>/dev/null || true

# Start the application
echo "🚀 Starting Django Application..."
nohup python3 manage.py runserver 0.0.0.0:8000 > app.log 2>&1 &

echo "✅ Deployment successful!"
