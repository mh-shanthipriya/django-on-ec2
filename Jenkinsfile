pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '571600845308'  // Updated AWS Account ID
        AWS_REGION = 'ap-southeast-2'  // Updated AWS Region
        EC2_USER = 'ubuntu'
        EC2_HOST = '54.252.172.203'  // Updated EC2 Host IP
        APP_DIR = "/home/ubuntu/jenkins/jenkins/workspace/get_deploy_develop/todoApp"
        ECR_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/todoapp"
        PYTHON_BIN = '/usr/bin/python3'
        SSH_CREDENTIAL_ID = 'finalsshkeycredentials'  // Keeping the same SSH credentials
    }

    stages {
        stage('Clone Repository') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'new-token',
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_PASSWORD'
                )]) {
                    sh '''
                    echo "Checking if repository already exists..."
                    if [ -d "django-on-ec2/.git" ]; then
                        echo "Repository exists. Pulling latest changes..."
                        cd django-on-ec2
                        git remote set-url origin https://$GIT_USERNAME:$GIT_PASSWORD@github.com/mh-shanthipriya/django-on-ec2.git
                        git fetch origin develop
                        git reset --hard origin/develop
                        git pull origin develop
                    else
                        echo "Cloning Django repository..."
                        git clone -b develop https://$GIT_USERNAME:$GIT_PASSWORD@github.com/mh-shanthipriya/django-on-ec2.git
                    fi
                    '''
                }
            }
        }

        stage('Run Pylint Checks') {
            steps {
                sh '''
                echo "Running Pylint Checks..."
                if [ -f django-on-ec2/pylint.sh ]; then
                    chmod +x django-on-ec2/pylint.sh
                    ./django-on-ec2/pylint.sh | tee pylint.log || echo "⚠️ Pylint warnings found, review pylint.log."
                else
                    echo "❌ pylint.sh not found. Skipping pylint checks."
                fi
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                echo "Building Docker Image..."
                cd django-on-ec2
                docker build -t todoapp -f Dockerfile .
                docker tag todoapp:latest $ECR_URI:latest
                '''
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([string(credentialsId: 'awscredential', variable: 'AWS_ECR_PASSWORD')]) {
                    sh '''
                    echo "Logging into AWS ECR..."
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI
                    '''
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                sh '''
                echo "Pushing Docker Image to AWS ECR..."
                docker push $ECR_URI:latest
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent([SSH_CREDENTIAL_ID]) {
                    sh '''
                    echo "Deploying on EC2..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << EOF
                    set -e
                    echo 'Checking for existing container...'
                    docker ps -q --filter 'name=todo-container' | grep -q . && docker stop todo-container && docker rm -f todo-container || echo 'No running container found.'

                    echo 'Checking for processes using port 8000...'
                    sudo lsof -ti:8000 | xargs -r sudo kill -9 || echo 'No process found on port 8000.'

                    echo 'Pulling latest image from ECR...'
                    docker pull $ECR_URI:latest

                    echo 'Running new container...'
                    docker run -d --restart=always -p 8000:8000 --name todo-container $ECR_URI:latest
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
