pipeline {
    agent any

    tools {
        nodejs 'NodeJS-22'
    }

    environment {
        IMAGE_NAME = 'chetima/nodejs-ci'
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    stages {

        stage('Install Dependencies') {
            steps {
                echo '===== INSTALLING DEPENDENCIES ====='
                sh 'node --version'
                sh 'npm --version'
                sh 'npm ci'
            }
        }

        stage('Test') {
            steps {
                echo '===== RUNNING TESTS ====='
                sh 'npm test'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '===== BUILDING DOCKER IMAGE ====='

                sh """
                    docker build \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${IMAGE_NAME}:latest \
                        .
                """
            }
        }

        stage('Docker Login') {
            steps {
                echo '===== PUSHING TO DOCKER HUB ====='

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login \
                            --username "$DOCKER_USERNAME" \
                            --password-stdin
                    '''
                }
            }
        }

        stage('Docker Push') {
            steps {
                sh '''
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl set image deployment/nodejs-app \
                     nodejs-app=${IMAGE_NAME}:${IMAGE_TAG} \
                     -n jenkins-demo

                    kubectl rollout status deployment/nodejs-app \
                      -n jenkins-demo
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl get deployment \
                     nodejs-app \
                     -n jenkins-demo

                    kubectl get pods \
                     -n jenkins-demo \
                     -l app=nodejs-app
                '''
            }
        }
    }

    post {
        success {
            echo '======================================'
            echo '     CI/CD PIPELINE SUCCESSFUL!       '
            echo '======================================'
            echo "Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
        }

        failure {
            echo '======================================'
            echo '       CI/CD PIPELINE FAILED!         '
            echo '======================================'
        }

        always {
            echo "Build #${BUILD_NUMBER} finished."
        }
    }
}