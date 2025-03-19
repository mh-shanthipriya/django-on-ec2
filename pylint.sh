#!/bin/bash
# Enforce strict error handling
set -euxo pipefail  

# Define the correct APP_DIR path for the deployment server
APP_DIR="/home/ubuntu/jenkins/jenkins/workspace/git_deploy_develop_2/django-on-ec2"

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
    source "venv/bin/activate"
else
    echo "⚠️ Virtual environment not found. Creating one..."
    python3 -m venv venv
    source "venv/bin/activate"
    pip install -r requirements.txt
fi

# Run Pylint checks with customized rules
echo "🔍 Running Pylint Checks..."
python3 -m pylint \
    --disable=missing-docstring,invalid-name,trailing-whitespace,line-too-long,no-member,import-outside-toplevel \
    --max-line-length=120 \
    todoApp todos manage.py | tee pylint.log || {
    echo "❌ Pylint checks failed. Fix issues before proceeding!"
    exit 1
}

# Ensure no existing process is running on port 8000
echo "🔍 Checking for existing process on port 8000..."
if [ -f "app.pid" ]; then
    PID=$(cat app.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "🛑 Stopping existing Django application with PID: $PID"
        kill -9 $PID
    fi
    rm -f app.pid
else
    echo "⚠️ No PID file found. Checking port directly..."
    fuser -k 8000/tcp || echo "✅ No process found on port 8000."
fi

# Rotate logs
if [ -f "app.log" ]; then
    echo "🔄 Rotating logs..."
    mv app.log app.log.bak
fi

# Start the application
echo "🚀 Starting Django Application..."
nohup python3 manage.py runserver 0.0.0.0:8000 > app.log 2>&1 &
echo $! > app.pid

echo "✅ Deployment successful!"
