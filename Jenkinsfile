pipeline {
    agent any

    tools {
        nodejs 'NodeJS-22'
    }

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['development', 'staging', 'production'],
            description: 'Select deployment environment'
        )
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(
            logRotator(
                numToKeepStr: '10'
            )
        )
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

        stage('Quality Checks') {
            parallel {
                stage('Lint') {
                    steps {
                        sh 'node --check app.js'
                    }
                }
                stage('Tests') {
                    steps {
                        sh 'npm test'
                    }
                }
            }
        }

        stage('Build') {
            steps {
                sh '''
                    rm -rf build
                    mkdir build
                    cp app.js build/
                    cp package.json build/
                    echo 'build completed successfully'
                '''
            }
        }

        stage('Approval') {
            when {
                expression {
                    params.ENVIRONMENT == 'production'
                }
            }
            steps {
                input message: 'Deploy to production?'
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploying ${APP_NAME} to ${params.ENVIRONMENT}"
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
