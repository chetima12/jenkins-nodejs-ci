pipeline {
    agent any

    tools {
        nodejs 'NodeJS-20'
    }

    environment {
        IMAGE_NAME = 'chetima/nodejs-ci'
        IMAGE_TAG  = "${BUILD_NUMBER}"
        DOCKER_BUILDKIT = '1'
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Branch Info') {
            steps {
                echo "Branch: ${env.BRANCH_NAME ?: env.GIT_BRANCH}"
                echo "Build Number: ${env.BUILD_NUMBER}"
            }
        }

        stage('Install Dependencies') {
            steps {
                echo '===== INSTALLING DEPENDENCIES ====='
                script {
                    if (!fileExists('node_modules')) {
                        sh 'npm ci'
                    } else {
                        echo 'Dependencies already present (node_modules exists). Skipping npm ci.'
                    }
                }
            }
        }

        stage('Test') {
            steps {
                echo '===== RUNNING TESTS ====='
                sh 'npm test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    echo '===== OPTIMIZED SONARQUBE ANALYSIS ====='

                    withEnv(['SONAR_SCANNER_OPTS=-Xmx2048m -XX:+UseG1GC']) {
                        withSonarQubeEnv('SonarQube') {
                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                    -Dsonar.exclusions="**/node_modules/**,**/dist/**,**/build/**,**/coverage/**,package-lock.json" \
                                    -Dsonar.sources=.
                            """
                        }
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

        stage('Docker Login & Build') {
            steps {
                echo '===== DOCKER LOGIN & BUILD ====='
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                    '''
                    sh """
                        docker build \
                            --build-arg BUILDKIT_INLINE_CACHE=1 \
                            --cache-from ${IMAGE_NAME}:latest \
                            -t ${IMAGE_NAME}:${IMAGE_TAG} \
                            -t ${IMAGE_NAME}:latest \
                            .
                    """
                }
            }
        }

        stage('Docker Push') {
            
            steps {
                sh """
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${IMAGE_NAME}:latest
                """
            }
        }

       

        stage('Deploy Production') {
            
            steps {
                sh """
                    kubectl set image deployment/nodejs-app \
                        nodejs-app=${IMAGE_NAME}:${IMAGE_TAG} \
                        -n jenkins-demo

                    kubectl rollout status deployment/nodejs-app \
                        -n jenkins-demo
                """
            }
        }

        stage('Verify Deployment') {
            
            steps {
                sh """
                    kubectl get deployment nodejs-app -n jenkins-demo
                    kubectl get pods -n jenkins-demo -l app=nodejs-app
                """
            }
        }
    }

    post {
        always {
            echo "Build #${BUILD_NUMBER} finished."
        }
        success {
            echo '======================================'
            echo '     CI/CD PIPELINE SUCCESSFUL!       '
            echo '======================================'
        }
        failure {
            echo '======================================'
            echo '       CI/CD PIPELINE FAILED!         '
            echo '======================================'
        }
    }
}