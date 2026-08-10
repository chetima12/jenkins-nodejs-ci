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

        stage('Push to Docker Hub') {
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

                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest

                        docker logout
                    '''
                }
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