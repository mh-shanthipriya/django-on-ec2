pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '571600845308'  // Updated AWS Account ID
        AWS_REGION = 'ap-southeast-2'  // Updated AWS Region
        EC2_USER = 'ubuntu'
        EC2_HOST = '54.252.172.203'  // Updated EC2 Host IP
        SSH_CREDENTIAL_ID = 'finalsshkeycredentials'  // Updated SSH credentials ID
        APP_DIR = "/home/ubuntu/jenkins/jenkins/workspace/git_deploy_develop"
    }

    stages {
        stage('Checkout Code') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'new-token',  // Updated GitHub credentials ID
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_PASSWORD'
                )]) {
                    sh '''
                    echo "🔄 Cloning repository..."
                    if [ ! -d "django-on-ec2" ]; then
                        git clone https://$GIT_USERNAME:$GIT_PASSWORD@github.com/mh-shanthipriya/django-on-ec2.git
                    else
                        cd django-on-ec2 && git pull
                    fi
                    '''
                }
            }
        }

        stage('Run Pylint Tests') {
            steps {
                sh '''
                echo "🔍 Running Pylint Tests..."
                set -e
                if [ -f ./pylint.sh ]; then
                    chmod +x ./pylint.sh
                    ./pylint.sh | tee pylint.log
                else
                    echo "❗ pylint.sh not found — Skipping Pylint Tests."
                fi
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent([SSH_CREDENTIAL_ID]) {
                    sh '''
                    echo "🚀 Deploying to EC2..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << EOF
                    set -e

                    echo "🔑 Setting up environment on EC2..."
                    cd $APP_DIR

                    if [ ! -d "venv" ]; then
                        python3 -m venv venv
                    fi

                    source venv/bin/activate
                    pip install --upgrade pip setuptools wheel

                    echo "🔄 Installing dependencies..."
                    if [ -f "requirements.txt" ]; then
                        pip install -r requirements.txt || exit 1
                    else
                        echo "❌ requirements.txt not found. Exiting..."
                        exit 1
                    fi

                    echo "🔄 Running migrations..."
                    python manage.py migrate

                    echo "🟢 Starting Django application..."
                    sudo systemctl restart todoApp || echo "❌ Failed to restart Django application"

                    echo "📊 Checking application status..."
                    sudo systemctl status todoApp --no-pager
EOF
                    '''
                }
            }
        }
    }

    post {
        always {
            echo '🟢 Pipeline Completed!!!'
        }
        failure {
            echo '❗ Pipeline Failed — Please Check Logs.'
        }
    }
}
