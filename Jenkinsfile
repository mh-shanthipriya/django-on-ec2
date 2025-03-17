pipeline {
    agent { label 'docker-agent-label' }

    environment {
        AWS_ACCOUNT_ID = '571600845308'
        AWS_REGION = 'ap-southeast-2'
        EC2_USER = 'ubuntu'
        EC2_HOST = '3.27.60.227'
        APP_DIR = '/home/ubuntu/todo-app'
        PYTHON_BIN = '/usr/bin/python3'
    }

    stages {
        stage('Install Dependencies') {
            steps {
                sh '''
                echo "Checking and Installing Git if not available..."
                if ! command -v git &> /dev/null; then 
                    sudo apt update && sudo apt install -y git; 
                fi
                '''
            }
        }

        stage('Clone Repository') {
            steps {
                withCredentials([usernamePassword(credentialsId: '91ba94ac-f61b-4f67-899f-0755b3e48bef', 
                                                  usernameVariable: 'GIT_USERNAME', 
                                                  passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                    echo "Configuring Git Credentials Securely..."
                    export GIT_ASKPASS=/tmp/git_askpass.sh
                    echo '#!/bin/sh' > $GIT_ASKPASS
                    echo 'echo "$GIT_PASSWORD"' >> $GIT_ASKPASS
                    chmod +x $GIT_ASKPASS

                    echo "Cloning Repository..."
                    rm -rf $APP_DIR
                    git clone --depth 1 https://$GIT_USERNAME@github.com/mh-shanthipriya/django-on-ec2.git $APP_DIR || exit 1
                    '''
                }
            }
        }

        stage('Run Pylint Checks') {
            steps {
                sh '''
                echo "Running Pylint Checks..."
                sudo apt update
                sudo apt install -y python3-pip  # Ensure pip is installed
                cd $APP_DIR

                # Check if pylint.sh exists, and if not, create one for linting
                if [ ! -f "pylint.sh" ]; then
                    echo "#!/bin/bash" > pylint.sh
                    echo "pylint \$(find . -name '*.py')" >> pylint.sh
                    chmod +x pylint.sh
                fi

                ./pylint.sh || exit 1
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['finalsshkeycredentials']) {
                    sh '''
                    echo "Testing SSH Connection..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "echo 'SSH Connection Successful'"

                    echo "Transferring application files to EC2..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "rm -rf $APP_DIR && mkdir -p $APP_DIR"
                    scp -o StrictHostKeyChecking=no -r $APP_DIR/* $EC2_USER@$EC2_HOST:$APP_DIR

                    echo "Deploying Application..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << EOF
                    cd $APP_DIR
                    if [ ! -d "venv" ]; then 
                        python3 -m venv venv; 
                    fi
                    source venv/bin/activate
                    pip install --upgrade pip setuptools wheel
                    pip install -r requirements.txt || exit 1

                    echo "Setting up Systemd Service for Uvicorn..."
                    sudo tee /etc/systemd/system/todo-app.service > /dev/null <<EOL
                    [Unit]
                    Description=Todo App Service
                    After=network.target

                    [Service]
                    User=$EC2_USER
                    WorkingDirectory=$APP_DIR
                    ExecStart=$APP_DIR/venv/bin/uvicorn app:app --host 0.0.0.0 --port 8000
                    Restart=always

                    [Install]
                    WantedBy=multi-user.target
                    EOL

                    echo "Restarting Application..."
                    sudo systemctl daemon-reload
                    sudo systemctl enable todo-app
                    sudo systemctl restart todo-app
                    sudo systemctl status todo-app --no-pager
                    EOF
                    '''
                }
            }
        }
    }
}
