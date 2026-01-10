pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME   = "mgelvoleo/python-webapp"
        IMAGE_TAG    = "1.0.${BUILD_NUMBER}"
        KEEP_IMAGES  = "5"
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

        stage('Build & Push Docker Image') {
            steps {
                sh '''
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Cleanup Local Docker Images') {
            steps {
                sh '''
                    echo "🧹 Cleaning up local Docker images (keeping latest ${KEEP_IMAGES})"

                    docker images ${IMAGE_NAME} --format "{{.Repository}}:{{.Tag}} {{.CreatedAt}}" | \
                    sort -rk2 | \
                    tail -n +$((${KEEP_IMAGES}+1)) | \
                    awk '{print $1}' | \
                    xargs -r docker rmi -f || true
                '''
            }
        }

        stage('Cleanup Docker Hub Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo "🧹 Cleaning up Docker Hub images (keeping latest ${KEEP_IMAGES})"

                    TOKEN=$(curl -s -X POST https://hub.docker.com/v2/users/login/ \
                      -H "Content-Type: application/json" \
                      -d '{"username": "'$DOCKER_USER'", "password": "'$DOCKER_PASS'"}' | jq -r .token)

                    curl -s -H "Authorization: JWT $TOKEN" \
                      "https://hub.docker.com/v2/repositories/${IMAGE_NAME}/tags/?page_size=100" | \
                    jq -r '.results | map(select(.name | startswith("1.0."))) | sort_by(.last_updated) | reverse | .[5:] | .[].name' | \
                    while read TAG; do
                        echo "Deleting remote tag: $TAG"
                        curl -s -X DELETE \
                          -H "Authorization: JWT $TOKEN" \
                          "https://hub.docker.com/v2/repositories/${IMAGE_NAME}/tags/$TAG/"
                    done
                    '''
                }
            }
        }

        /* ============
        CD: DEV ENVIRONMENT
        =============== */
        stage('Deploy to Dev environment') {
            
            environment {
                K8S_NS = "dev"
            }

            steps {
                sh '''
                    kubectl apply -f k8s/dev/namespace.yaml
                    kubectl apply -f k8s/dev/deployment.yaml -n ${K8S_NS}
                    kubectl set image deployment/python-app \
                        python-app=${IMAGE_NAME}:${IMAGE_TAG} \
                        -n ${K8S_NS}
                    kubectl apply -f k8s/dev/service.yaml -n ${K8S_NS}
                    kubectl rollout status deployment/python-app -n ${K8S_NS}
                '''
            }
        }


        /* =======================
           CD: TEST
        ======================= */

        stage('Deploy to TEST') {
            when {
                branch 'main'
            }
            environment {
                K8S_NS = "test"
            }
            steps {
                sh '''
                    echo "🚀 Deploying to TEST"

                    kubectl apply -f k8s/test/namespace.yaml
                    kubectl apply -f k8s/test/deployment.yaml -n ${K8S_NS}

                    kubectl set image deployment/python-app \
                        python-app=${IMAGE_NAME}:${IMAGE_TAG} \
                        -n ${K8S_NS}

                    kubectl apply -f k8s/test/service.yaml -n ${K8S_NS}
                    kubectl rollout status deployment/python-app -n ${K8S_NS}
                '''
            }
        }

        stage('Smoke Test (TEST)') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    echo "🔍 Running smoke test on TEST"
                    kubectl get pods -n test
                '''
            }
        }

        /* =======================
           CD: PROD
        ======================= */

        stage('Approval for PROD') {
            when {
                branch 'release'
            }
            steps {
                input message: "Deploy to PROD?", ok: "Deploy"
            }
        }


        stage('Deploy to PROD') {
            
            when {
                branch 'release'
            }
           
            environment {
                K8S_NS = "prod"
            }

            steps {
                sh '''
                    echo "🚀 Deploying to PROD"

                    kubectl apply -f k8s/prod/namespace.yaml
                    kubectl apply -f k8s/prod/deployment.yaml -n ${K8S_NS}

                    kubectl set image deployment/python-app \
                        python-app=${IMAGE_NAME}:${IMAGE_TAG} \
                        -n ${K8S_NS}

                    kubectl apply -f k8s/prod/service.yaml -n ${K8S_NS}
                    kubectl rollout status deployment/python-app -n ${K8S_NS}
                '''
            }

        }

        
    }

    post {
        failure {
            echo "❌ CI failed. Deployment skipped."
        }
        success {
            sh 'docker logout || true'
            echo "✅ CI/CD pipeline completed successfully."
        }
    }
}
