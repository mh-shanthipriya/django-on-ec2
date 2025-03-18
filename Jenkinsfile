pipeline {
    agent { label 'docker-agent-label' }

    environment {
        AWS_ACCOUNT_ID = '571600845308'
        AWS_REGION = 'ap-southeast-2'
        EC2_USER = 'ubuntu'
        EC2_HOST = '54.252.172.203'
        APP_DIR = "/home/ubuntu/jenkins/jenkins/workspace/git_deploy_develop"

        PYTHON_BIN = '/usr/bin/python3'
    }

    stages {
        stage('Clone Repository') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: '91ba94ac-f61b-4f67-899f-0755b3e48bef',
                    usernameVariable: 'GIT_USERNAME', 
                    passwordVariable: 'GIT_PASSWORD'
                )]) {
                    sh '''
                    echo "🧹 Cleaning old workspace if exists..."
                    if [ -d "$APP_DIR/.git" ]; then
                        echo "❗ Previous Git repository detected. Cleaning workspace properly..."
                        rm -rf $APP_DIR
                    fi
                    mkdir -p $APP_DIR

                    echo "🔄 Cloning repository..."
                    git clone --depth 1 https://$GIT_USERNAME@github.com/mh-shanthipriya/django-on-ec2.git $APP_DIR || exit 1

                    # Verify Workspace
                    if [ -d "$APP_DIR" ]; then
                        echo "✅ Workspace created successfully: $APP_DIR"
                    else
                        echo "❌ Workspace creation failed."
                        exit 1
                    fi
                    '''
                }
            }
        }

        stage('Run Pylint Checks') {
            steps {
                sh '''
                echo "🚨 Running Pylint Checks..."
                cd $APP_DIR

                if [ -f "./pylint.sh" ]; then
                    chmod +x pylint.sh
                    ./pylint.sh || echo "⚠️ Pylint errors found, review logs."
                else
                    echo "❗ pylint.sh not found. Skipping lint checks..."
                fi
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['finalsshkeycredentials']) {
                    sh '''
                    echo "🔐 Testing SSH Connection..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "echo 'SSH Connection Successful'" || exit 1

                    echo "📂 Creating app directory on EC2..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "rm -rf $APP_DIR && mkdir -p $APP_DIR"

                    echo "📤 Transferring application files to EC2..."
                    rsync -av --exclude '.git' --exclude 'venv' --exclude '__pycache__' $APP_DIR/ $EC2_USER@$EC2_HOST:$APP_DIR/

                    echo "🚀 Deploying Application..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << EOF
                    cd $APP_DIR

                    if [ ! -d "venv" ]; then 
                        python3 -m venv venv; 
                    fi
                    source venv/bin/activate
                    pip install --upgrade pip setuptools wheel
                    echo "$(pwd)"
                    if [ -f "requirements.txt" ]; then 
                        pip install -r requirements.txt || exit 1
                    else
                        echo "❌ requirements.txt not found. Exiting..."
                        exit 1
                    fi

                    echo "🟢 Setting up Systemd Service for Django..."
                    sudo bash -c 'cat <<EOL > /etc/systemd/system/todoApp.service
                    [Unit]
                    Description=Todo App Service
                    After=network.target

                    [Service]
                    User=$EC2_USER
                    WorkingDirectory=$APP_DIR/todoApp
                    ExecStart=$APP_DIR/venv/bin/python3 manage.py runserver 0.0.0.0:8000
                    Restart=always

                    [Install]
                    WantedBy=multi-user.target
                    EOL'
