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

# Activate virtual environment (if available)
if [ -d "venv" ]; then
    echo "✅ Activating Virtual Environment"
    source venv/bin/activate
else
    echo "⚠️ Virtual environment not found. Installing dependencies..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

# Run database migrations
echo "📦 Running Migrations..."
python3 manage.py migrate

# Run Pylint checks
echo "🔍 Running Pylint Checks..."
python3 -m pylint todoApp todos manage.py | tee pylint.log || echo "⚠️ Pylint warnings found, review pylint.log."

# Collect static files
echo "📁 Collecting static files..."
python3 manage.py collectstatic --noinput

# Stop any running Django instance on port 8000
echo "🛑 Stopping existing Django application (if any)..."
pkill -f "manage.py runserver" || echo "⚠️ No existing Django process found."

# Start the application
echo "🚀 Starting Django Application..."
nohup python3 manage.py runserver 0.0.0.0:8000 > app.log 2>&1 &

echo "✅ Deployment successful!"
