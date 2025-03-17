pipeline {
    agent { label 'docker-agent-label' }

    environment {
        AWS_ACCOUNT_ID = '571600845308'
        AWS_REGION = 'ap-southeast-2'
        EC2_USER = 'ubuntu'
        EC2_HOST = '3.27.60.227'  // Your deployment server public IP
        APP_DIR = '/home/ubuntu/todo-app'
        PYTHON_BIN = '/usr/bin/python3'
    }

    stages {
        stage('Clone Repository') {
            steps {
                withCredentials([string(credentialsId: '2ee8dcbe-91a7-46a3-b720-39e9cd07db57', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                    echo "Cloning repository..."
                    rm -rf $APP_DIR  # Ensure a fresh clone
                    git clone https://$GITHUB_TOKEN@github.com/mh-shanthipriya/django-on-ec2.git $APP_DIR || exit 1
                    '''
                }
            }
        }

        stage('Run Pylint Checks') {
            steps {
                sh '''
                echo "Running Pylint Checks..."
                cd $APP_DIR
                chmod +x pylint.sh
                ./pylint.sh || true  # Prevent failure from stopping pipeline
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['finalsshkeycredentials']) {  // Update with your EC2 SSH credentials
                    sh '''
                    echo "Testing SSH Connection..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "echo 'SSH Connection Successful'"

                    echo "Transferring application files to EC2..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "rm -rf $APP_DIR && mkdir -p $APP_DIR"
                    scp -o StrictHostKeyChecking=no -r $APP_DIR/* $EC2_USER@$EC2_HOST:$APP_DIR

                    echo "Starting application using Uvicorn..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << EOF
                    cd $APP_DIR
                    if [ ! -d "venv" ]; then python3 -m venv venv; fi
                    source venv/bin/activate
                    echo "Installing dependencies..."
                    pip install --upgrade pip setuptools wheel
                    pip install -r requirements.txt || exit 1

                    echo "Restarting Uvicorn if already running..."
                    pgrep -f "uvicorn" && pkill -f "uvicorn"

                    echo "Starting Uvicorn..."
                    nohup uvicorn app:app --host 0.0.0.0 --port 8000 > app.log 2>&1 &
                    EOF
                    '''
                }
            }
        }
    }
}
