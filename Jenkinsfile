pipeline {
    agent any
        stages {
            stage ('Install') {
                step {
                    sh 'npm install'
                }
            }
            stage ('Test') {
                step {
                    sh 'npm test'
                }
            }
            stage ('Build') {
                step {
                    sh 'echo "echo building application"'
                }
            }
        }
    
}