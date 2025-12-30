pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DOCKER_VM = "192.168.60.7"
        IMAGE_NAME = "python-webapp"
        IMAGE_TAG  = "1.0.${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                ssh dockeruser@${DOCKER_VM} "
                  cd /tmp &&
                  rm -rf python-webapp &&
                  git clone https://github.com/mgelvoleo/python-project.git python-webapp &&
                  cd python-webapp &&
                  docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                "
                '''
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                ssh dockeruser@${DOCKER_VM} "
                  docker stop web || true &&
                  docker rm web || true &&
                  docker run -d --name web -p 8000:8000 ${IMAGE_NAME}:${IMAGE_TAG}
                "
                '''
            }
        }
    }
}
