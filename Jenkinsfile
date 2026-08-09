pipeline {
    agent any

    tools {
        nodejs 'NodeJS-22'
    }

    environment {
        APP_NAME = 'nodejs-ci'
    }

    stages {

        stage('Environment') {
            steps {
                sh '''
                    echo "Application: $APP_NAME"
                    echo "Job: $JOB_NAME"
                    echo "Build: $BUILD_NUMBER"
                '''
            }
        }

        stage('Install') {
            steps {
                sh '''
                    echo "===== NODE VERSION ====="
                    node --version

                    echo "===== NPM VERSION ====="
                    npm --version

                    echo "===== INSTALLING DEPENDENCIES ====="
                    npm install
                '''
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }
        }

        stage('Build') {
            steps {
                sh 'echo "Build completed successfully"'
            }
        }
    }

    post {
        success {
            echo '===== CI PIPELINE SUCCESS ====='
        }

        failure {
            echo '===== CI PIPELINE FAILED ====='
        }

        always {
            echo '===== PIPELINE FINISHED ======'
        }
    }
}