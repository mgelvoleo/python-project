pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME = "mgelvoleo/python-webapp"
        IMAGE_TAG  = "1.0.${BUILD_NUMBER}"
        K8S_NS     = "dev"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Lint') {
            steps {
                sh '''
                python3 -m venv venv
                source venv/bin/activate
                pip install flake8
                flake8 app.py
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                source venv/bin/activate
                pip install pytest
                pytest tests/
                '''
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                docker push ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                sed "s|IMAGE_NAME|${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml | kubectl apply -f -
                kubectl apply -f k8s/namespace.yaml
                kubectl apply -f k8s/service.yaml
                '''
            }
        }
    }
    
    post {
        failure {
            echo "❌ CI failed. Deployment skipped."
        }
        success {
            echo "✅ CI/CD pipeline completed successfully."
        }
    }
}