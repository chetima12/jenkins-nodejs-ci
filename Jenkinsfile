pipeline {

    agent any

    tools {
        nodejs 'NodeJS-20'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(
            logRotator(numToKeepStr: '10')
        )
        skipDefaultCheckout(true)
    }

    environment {
        AWS_REGION     = 'us-east-1'
        EKS_CLUSTER    = 'prod-eks-cluster'
        ECR_REPOSITORY = 'jenkins-nodejs-app'
        IMAGE_NAME     = 'jenkins-nodejs-app'
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {

        /*
         * ==========================================
         * CHECKOUT
         * ==========================================
         */

        stage('Checkout') {
            steps {
                echo '================================='
                echo 'Checking Out Source Code'
                echo '================================='

                checkout scm

                sh '''
                    set -e

                    echo ""
                    echo "Git commit:"
                    git rev-parse --short HEAD

                    echo ""
                    echo "Git branch:"
                    git branch --show-current || true

                    echo ""
                    echo "Git remote:"
                    git remote get-url origin || true
                '''
            }
        }


        /*
         * ==========================================
         * ENVIRONMENT
         * ==========================================
         */

        stage('Environment Check') {
            steps {
                sh '''
                    set -e

                    echo '================================='
                    echo 'Environment Check'
                    echo '================================='

                    echo ""
                    echo "Node.js:"
                    node --version

                    echo ""
                    echo "npm:"
                    npm --version

                    echo ""
                    echo "Docker:"
                    docker --version

                    echo ""
                    echo "AWS CLI:"
                    aws --version

                    echo ""
                    echo "kubectl:"
                    kubectl version --client

                    echo ""
                    echo "Helm:"
                    helm version

                    echo ""
                    echo "Trivy:"
                    trivy --version

                    echo ""
                    echo "Jenkins Build:"
                    echo "${BUILD_NUMBER}"
                '''
            }
        }


        /*
         * ==========================================
         * INSTALL + TEST
         * ==========================================
         */

        stage('Install & Test') {
            steps {
                
                    sh '''
                        set -e

                        echo '================================='
                        echo 'Install Dependencies'
                        echo '================================='

                        npm ci

                        echo ""
                        echo "================================="
                        echo "Run Unit Tests"
                        echo "================================="

                        npm test
                    '''
                
            }
        }


        /*
         * ==========================================
         * SONARQUBE
         * ==========================================
         */

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool(
                        name: 'SonarScanner',
                        type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                    )

                    withSonarQubeEnv('SonarQube') {
                        sh """
                            set -e

                            echo '================================='
                            echo 'SonarQube Analysis'
                            echo '================================='

                            echo ""
                            echo "Running SonarQube analysis..."

                            ${scannerHome}/bin/sonar-scanner
                        """
                    }
                }
            }
        }


        /*
         * ==========================================
         * TRIVY FILESYSTEM SCAN
         * ==========================================
         */

        stage('Trivy FS Scan') {
            steps {
                sh '''
                    set -e

                    echo '================================='
                    echo 'Trivy Filesystem Scan'
                    echo '================================='

                    trivy fs \
                        --exit-code 1 \
                        --severity HIGH,CRITICAL \
                        --skip-dirs "node_modules" \
                        .

                    echo ""
                    echo "Trivy filesystem scan PASSED."
                '''
            }
        }


        /*
         * ==========================================
         * DOCKER BUILD
         * ==========================================
         */

        stage('Docker Build') {
            steps {
                sh '''
                    set -e

                    echo '================================='
                    echo 'Docker Build'
                    echo '================================='

                    echo ""
                    echo "Image:"
                    echo "${IMAGE_NAME}:${IMAGE_TAG}"

                    docker build \
                        --pull \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        .

                    echo ""
                    echo "Docker image successfully built."

                    docker images ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }


        /*
         * ==========================================
         * TRIVY IMAGE SCAN
         * ==========================================
         */

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    set -e

                    echo '================================='
                    echo 'Trivy Docker Image Scan'
                    echo '================================='

                    echo ""
                    echo "Scanning:"
                    echo "${IMAGE_NAME}:${IMAGE_TAG}"

                    trivy image \
                        --exit-code 1 \
                        --severity HIGH,CRITICAL \
                        --pkg-types os,library \
                        ${IMAGE_NAME}:${IMAGE_TAG}

                    echo ""
                    echo "================================="
                    echo "SECURITY SCAN PASSED"
                    echo "================================="

                    echo "No HIGH or CRITICAL vulnerabilities detected."
                '''
            }
        }


        /*
         * ==========================================
         * AWS / ECR
         * ==========================================
         */

        stage('AWS / ECR Validation') {
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]
                ]) {
                    sh '''
                        set -e

                        echo '================================='
                        echo 'AWS / ECR Validation'
                        echo '================================='

                        echo ""
                        echo "AWS Identity:"

                        aws sts get-caller-identity

                        AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                            --query Account \
                            --output text)

                        ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        ECR_URI=${ECR_REGISTRY}/${ECR_REPOSITORY}

                        echo ""
                        echo "AWS Account:"
                        echo "${AWS_ACCOUNT_ID}"

                        echo ""
                        echo "AWS Region:"
                        echo "${AWS_REGION}"

                        echo ""
                        echo "ECR Registry:"
                        echo "${ECR_REGISTRY}"

                        echo ""
                        echo "ECR Repository:"
                        echo "${ECR_REPOSITORY}"

                        echo ""
                        echo "ECR URI:"
                        echo "${ECR_URI}"

                        echo ""
                        echo "Checking ECR repository..."

                        aws ecr describe-repositories \
                            --repository-names ${ECR_REPOSITORY} \
                            --region ${AWS_REGION}

                        echo ""
                        echo "ECR validation PASSED."
                    '''
                }
            }
        }


        /*
         * ==========================================
         * ECR LOGIN
         * ==========================================
         */

        stage('ECR Login') {
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]
                ]) {
                    sh '''
                        set -e

                        echo '================================='
                        echo 'Amazon ECR Login'
                        echo '================================='

                        AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                            --query Account \
                            --output text)

                        ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                        aws ecr get-login-password \
                            --region ${AWS_REGION} | \
                        docker login \
                            --username AWS \
                            --password-stdin \
                            ${ECR_REGISTRY}

                        echo ""
                        echo "ECR login PASSED."
                    '''
                }
            }
        }


        /*
         * ==========================================
         * TAG + PUSH
         * ==========================================
         */

        stage('Push Image to ECR') {
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]
                ]) {
                    sh '''
                        set -e

                        echo '================================='
                        echo 'Push Docker Image to ECR'
                        echo '================================='

                        AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                            --query Account \
                            --output text)

                        ECR_URI=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}

                        echo ""
                        echo "Local image:"
                        echo "${IMAGE_NAME}:${IMAGE_TAG}"

                        echo ""
                        echo "ECR image:"
                        echo "${ECR_URI}:${IMAGE_TAG}"

                        echo ""
                        echo "Creating ECR tag..."

                        docker tag \
                            ${IMAGE_NAME}:${IMAGE_TAG} \
                            ${ECR_URI}:${IMAGE_TAG}

                        echo ""
                        echo "Pushing image..."

                        docker push \
                            ${ECR_URI}:${IMAGE_TAG}

                        echo ""
                        echo "================================="
                        echo "IMAGE PUSH SUCCESSFUL"
                        echo "================================="
                    '''
                }
            }
        }


        /*
         * ==========================================
         * VERIFY ECR IMAGE
         * ==========================================
         */

        stage('Verify ECR Image') {
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]
                ]) {
                    sh '''
                        set -e

                        echo '================================='
                        echo 'Verify ECR Image'
                        echo '================================='

                        aws ecr describe-images \
                            --repository-name ${ECR_REPOSITORY} \
                            --image-ids imageTag=${IMAGE_TAG} \
                            --region ${AWS_REGION}

                        echo ""
                        echo "ECR image verification PASSED."
                    '''
                }
            }
        }


        /*
         * ==========================================
         * GITOPS
         * ==========================================
         *
         * Jenkins does NOT deploy directly to EKS.
         * Jenkins updates Helm values in Git.
         * Argo CD detects the Git change and
         * deploys the new image to EKS.
         *
         * ==========================================
         */

        stage('Update GitOps Image Tag') {
            steps {
                sh '''
                    set -e

                    echo '================================='
                    echo 'Update GitOps Image Tag'
                    echo '================================='

                    echo ""
                    echo "New image tag:"
                    echo "${IMAGE_TAG}"

                    echo ""
                    echo "Current Helm values:"

                    cat helm/jenkins-nodejs-app/values.yaml

                    python3 <<'PY'
from pathlib import Path
import os
import re

path = Path("helm/jenkins-nodejs-app/values.yaml")

if not path.exists():
    raise SystemExit("ERROR: helm/jenkins-nodejs-app/values.yaml does not exist")

text = path.read_text()
tag = os.environ.get("IMAGE_TAG", "")

text, count = re.subn(
    r"(?m)^( *tag: *).*$",
    lambda match: match.group(1) + '"' + tag + '"',
    text,
    count=1
)

if count != 1:
    raise SystemExit("ERROR: Could not find image.tag in helm/jenkins-nodejs-app/values.yaml")

path.write_text(text)
PY

                    echo ""
                    echo "Updated Helm values:"

                    cat helm/jenkins-nodejs-app/values.yaml

                    echo ""
                    echo "Git diff:"

                    git diff -- helm/jenkins-nodejs-app/values.yaml
                '''
            }
        }


        /*
         * ==========================================
         * GIT COMMIT + PUSH
         * ==========================================
         */

        stage('Commit GitOps Change') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-credentials',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -eu

                        echo "================================="
                        echo "Commit GitOps Change"
                        echo "================================="

                        GITOPS_URL="https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/chetima12/jenkins-nodejs-ci.git"
                        VALUES_FILE="helm/jenkins-nodejs-app/values.yaml"
                        IMAGE_REPOSITORY=$(awk '/repository:/ { sub(/.*repository:[[:space:]]*/, ""); print; exit }' helm/jenkins-nodejs-app/values.yaml)

                        if [ -z "${IMAGE_REPOSITORY}" ]; then
                            echo "ERROR: Could not determine the ECR image repository"
                            exit 1
                        fi

                        git fetch "${GITOPS_URL}" main

                        echo "Checking out the latest GitOps main branch..."
                        git checkout --detach -f FETCH_HEAD

                        if [ ! -f "${VALUES_FILE}" ]; then
                            echo "ERROR: ${VALUES_FILE} does not exist in the GitOps repository"
                            exit 1
                        fi

                        export IMAGE_REPOSITORY IMAGE_TAG VALUES_FILE
                        python3 <<'PY'
from pathlib import Path
import os
import re

path = Path(os.environ["VALUES_FILE"])
text = path.read_text()
repository = os.environ["IMAGE_REPOSITORY"]
tag = os.environ["IMAGE_TAG"]

text, repository_count = re.subn(
    r"(?m)^( *repository: *).*$",
    lambda match: match.group(1) + repository,
    text,
    count=1,
)
text, tag_count = re.subn(
    r"(?m)^( *tag: *).*$",
    lambda match: match.group(1) + '"' + tag + '"',
    text,
    count=1,
)

if repository_count != 1 or tag_count != 1:
    raise SystemExit("ERROR: Could not update image.repository and image.tag")

path.write_text(text)
PY

                        git config user.name "jenkins"
                        git config user.email "jenkins@localhost"
                        git add "${VALUES_FILE}"

                        if git diff --cached --quiet; then
                            echo "No GitOps changes detected."
                            exit 0
                        fi

                        git commit -m "chore: deploy jenkins-nodejs-app ${IMAGE_TAG}"

                        echo ""
                        echo "Git commit created:"
                        git log -1 --oneline

                        echo ""
                        echo "Pushing GitOps change to GitHub..."

                        git push \
                            "${GITOPS_URL}" \
                            HEAD:main

                        echo ""
                        echo "GitOps push successful."
                    '''
                }
            }
        }


        /*
         * ==========================================
         * GITOPS SUMMARY
         * ==========================================
         */

        stage('GitOps Deployment Summary') {
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]
                ]) {
                    sh '''
                        set -e

                        echo '================================='
                        echo 'GitOps Deployment Summary'
                        echo '================================='

                        AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                            --query Account \
                            --output text)

                        ECR_URI=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}

                        echo ""
                        echo "Application:"
                        echo "jenkins-nodejs-app"

                        echo ""
                        echo "Image:"
                        echo "${ECR_URI}:${IMAGE_TAG}"

                        echo ""
                        echo "GitOps file:"
                        echo "helm/jenkins-nodejs-app/values.yaml"

                        echo ""
                        echo "Image tag:"
                        grep -A3 '^image:' helm/jenkins-nodejs-app/values.yaml || true

                        echo ""
                        echo "================================="
                        echo "Argo CD will now reconcile EKS"
                        echo "================================="

                        echo ""
                        echo "Jenkins CI: COMPLETE"
                        echo "ECR Push: COMPLETE"
                        echo "GitOps Update: COMPLETE"
                        echo "Argo CD CD: PENDING/AUTOMATIC"
                    '''
                }
            }
        }
    }


    /*
     * ==========================================
     * POST ACTIONS
     * ==========================================
     */

    post {

        success {
            echo '================================='
            echo 'CI/CD PIPELINE SUCCESSFUL'
            echo '================================='

            echo "Build Number: ${BUILD_NUMBER}"
            echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
            echo "ECR Repository: ${ECR_REPOSITORY}"
            echo "EKS Cluster: ${EKS_CLUSTER}"

            echo ""
            echo "Argo CD should now detect the GitOps change."
        }


        failure {
            echo '================================='
            echo 'CI/CD PIPELINE FAILED'
            echo '================================='

            echo "Build Number: ${BUILD_NUMBER}"
            echo "Check the failed stage above."
        }


        always {
            echo '================================='
            echo 'Pipeline Cleanup'
            echo '================================='

            sh '''
                set +e

                echo "Removing local Docker images..."

                docker image rm \
                    ${IMAGE_NAME}:${IMAGE_TAG} \
                    2>/dev/null || true

                AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                    --query Account \
                    --output text \
                    2>/dev/null || true)

                if [ -n "${AWS_ACCOUNT_ID}" ]; then
                    ECR_URI=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}

                    docker image rm \
                        ${ECR_URI}:${IMAGE_TAG} \
                        2>/dev/null || true
                fi

                echo "Docker cleanup completed."
            '''

            cleanWs()
        }
    }
}