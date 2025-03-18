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
                withCredentials([string(credentialsId: 'git-hub-token', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                    echo "🧹 Cleaning old workspace if exists..."
                    rm -rf $APP_DIR
                    mkdir -p $APP_DIR

                    echo "🔄 Cloning repository..."
                    git clone --depth 1 https://$GITHUB_TOKEN@github.com/mh-shanthipriya/django-on-ec2.git $APP_DIR || exit 1
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
                    echo "🚀 Deploying Application..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'EOF'
cd $APP_DIR

# Kill existing server if running
echo "Stopping existing server..."
pkill -f "python3 manage.py runserver" || true

# Start new server
echo "Starting new Python web server..."
nohup python3 manage.py runserver 0.0.0.0:8000 > server.log 2>&1 &

echo "✅ Deployment Complete! Access at http://$EC2_HOST:8000"
EOF
                    '''
                }
            }
        }
    }

    post {
        always {
            echo '✅ Pipeline Completed!'
        }
        failure {
            echo '❌ Pipeline Failed — Please Check Logs.'
        }
    }
}
