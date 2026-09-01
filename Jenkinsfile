pipeline {
    agent any

    tools {
        nodejs 'NodeJS-20'
    }

    environment {
        IMAGE_NAME = 'chetima/nodejs-ci'
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(
            logRotator(numToKeepStr: '10')
        )
    }
    stages {

        stage('Branch Info') {
            steps {
                echo '===== BRANCH INFO ====='


                echo "Branch: ${env.BRANCH_NAME}"
                echo "Build Number: ${env.BUILD_NUMBER}"

            }
        }

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

        stage('Check SonarScanner') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    echo "===== SONARSCANNER CHECK ====="
                    echo "Scanner location: ${scannerHome}"

                    sh """
                        ${scannerHome}/bin/sonar-scanner --version
                   """
                }
            }
       }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    echo '===== SONARQUBE ANALYSIS ====='

                    withSonarQubeEnv('SonarQube') {
                        sh "${scannerHome}/bin/sonar-scanner"
                    }
                }
            }
        }


        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
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

            when {
                anyOf {
                    branch 'feature/login'
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                sh '''
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${IMAGE_NAME}:latest
                '''
            }
        }


        stage('Deploy Production') {
            when {
                branch 'main'
            }
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

        stage('Production Approval') {

            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy this image to production ?'
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