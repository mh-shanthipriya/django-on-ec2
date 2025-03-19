pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '571600845308'
        AWS_REGION = 'ap-southeast-2'
        EC2_USER = 'ubuntu'
        EC2_HOST = '54.252.172.203'
        APP_DIR = "/home/jenkins/workspace/git_deploy_develop/django-on-ec2"
        ECR_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/todoapp"
        PYTHON_BIN = '/usr/bin/python3'
        SSH_CREDENTIAL_ID = 'finalsshkeycredentials'
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
                    echo "🔄 Checking if repository exists..."
                    if [ -d "$APP_DIR/.git" ]; then
                        echo "✅ Repository exists. Pulling latest changes..."
                        cd $APP_DIR
                        git remote set-url origin https://$GIT_USERNAME:$GIT_PASSWORD@github.com/mh-shanthipriya/django-on-ec2.git
                        git fetch origin develop
                        git reset --hard origin/develop
                        git pull origin develop
                    else
                        echo "❗ Repository not found. Cloning new repository..."
                        git clone -b develop https://$GIT_USERNAME:$GIT_PASSWORD@github.com/mh-shanthipriya/django-on-ec2.git $APP_DIR
                    fi
                    '''
                }
            }
        }

        stage('Run Pylint Checks') {
            steps {
                sh '''
                echo "✅ Running Pylint Checks..."
                cd $APP_DIR
                if [ -f pylint.sh ]; then
                    chmod +x pylint.sh
                    ./pylint.sh | tee pylint.log || echo "⚠️ Pylint warnings found, review pylint.log."
                else
                    echo "❌ pylint.sh not found. Skipping pylint checks."
                fi
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                echo "🐳 Building Docker Image..."
                cd $APP_DIR
                docker build -t todoapp -f Dockerfile .
                docker tag todoapp:latest $ECR_URI:latest
                '''
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([string(credentialsId: 'awscredential', variable: 'AWS_ECR_PASSWORD')]) {
                    sh '''
                    echo "🔐 Logging into AWS ECR..."
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI
                    '''
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                sh '''
                echo "📤 Pushing Docker Image to AWS ECR..."
                docker push $ECR_URI:latest
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent([SSH_CREDENTIAL_ID]) {
                    sh '''
                    echo "🚀 Deploying on EC2..."
                    ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << EOF
                    set -e
                    echo '🔄 Checking for existing container...'
                    docker ps -q --filter 'name=todo-container' | grep -q . && docker stop todo-container && docker rm -f todo-container || echo '✅ No running container found.'

                    echo '🔎 Checking for processes using port 8000...'
                    sudo lsof -ti:8000 | xargs -r sudo kill -9 || echo '✅ No process found on port 8000.'

                    echo '📥 Pulling latest image from ECR...'
                    docker pull $ECR_URI:latest

                    echo '🚀 Running new container...'
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
