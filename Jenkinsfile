pipeline {
    agent any

    tools {
        nodejs 'NodeJS-22'
    }

    stages {

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
    }
}