pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    DOCKER_BUILDKIT      = '1'
    IMAGE_BACKEND        = 'workout-backend'
    IMAGE_FRONTEND       = 'workout-frontend'
    TAG                  = "${BRANCH_NAME.replace('/', '-')}-${BUILD_NUMBER}"
    AWS_REGION           = 'ap-south-1'
    ECR_REGISTRY         = '273809175099.dkr.ecr.ap-south-1.amazonaws.com'
    ECR_URI              = '273809175099.dkr.ecr.ap-south-1.amazonaws.com/dev_protfolio'
    PATH                 = "/var/jenkins_home/bin:${env.PATH}"
  }

  stages {
    stage('Checkout') {
      steps {
        cleanWs()
        checkout scm
      }
    }

    stage('Build Test Image') {
      steps {
        sh 'docker build -f Dockerfile.test -t backend-test:ci .'
      }
    }

    stage('Unit Tests') {
      steps {
        sh 'docker run --rm -v "$PWD/reports:/app/reports" backend-test:ci'
      }
    }

    stage('Package') {
      steps {
        sh 'docker build -t ${IMAGE_BACKEND}:${TAG} .'
        sh 'docker build -t ${IMAGE_FRONTEND}:${TAG} ./frontend'
      }
    }

    stage('Integration Test') {
      when {
        expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') }
      }
      steps {
        withCredentials([string(credentialsId: 'mongo-uri', variable: 'MONGO_URI')]) {
          sh '''
            export MONGO_URI="${MONGO_URI}"
            docker compose -f docker-compose.yaml up -d
            
            echo "=== Checking container status ==="
            docker compose ps
            
            echo "=== Backend logs (last 50 lines) ==="
            docker compose logs --tail=50 backend
            
            echo "=== DB logs (last 30 lines) ==="
            docker compose logs --tail=30 db

            chmod +x scripts/integration_check.sh || true
            bash scripts/integration_check.sh
          '''
        }
      }
    }

    stage('E2E Test') {
      when {
        expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') }
      }
      steps {
        sh '''
          chmod +x scripts/e2e_check.sh || true
          bash scripts/e2e_check.sh
        '''
      }
    }

    stage('Publish & Tag') {
      when {
        expression { env.BRANCH_NAME == 'main' }
      }
      steps {
        script {
          versionCalculationAndTag()
          echo "Version: ${env.CALCULATED_VERSION}"
        }

        withCredentials([[
          $class       : 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-jenkins-creds'
        ]]) {
          script {
            publishToECR()
          }
        }
      }
    }

    stage('Deploy') {
      when {
        expression { env.BRANCH_NAME == 'main' }
      }
      steps {
        withCredentials([usernamePassword(
          credentialsId   : 'gitlab-git-credentials',
          usernameVariable: 'GIT_USER',
          passwordVariable: 'GIT_TOKEN'
        )]) {
          sh '''
            set -eu

            BACKEND_TAG=backend-${CALCULATED_VERSION}
            FRONTEND_TAG=frontend-${CALCULATED_VERSION}

            rm -rf k8s-infra
            git clone https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/k8s-infra.git
            cd k8s-infra

            sed -i "s/tag: backend-.*/tag: ${BACKEND_TAG}/" charts/workout-stack/values.yaml
            sed -i "s/tag: frontend-.*/tag: ${FRONTEND_TAG}/" charts/workout-stack/values.yaml
            sed -i "s/^appVersion:.*/appVersion: ${CALCULATED_VERSION}/" charts/workout-stack/Chart.yaml

            git config user.email "ci@jenkins"
            git config user.name "Jenkins"
            
            git commit -am "ci: deploy ${BACKEND_TAG}/${FRONTEND_TAG} (${CALCULATED_VERSION}) [skip ci]"
            git push https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/k8s-infra.git main
          '''
        }
      }
    }
  }

  post {
    always {
      echo "Final cleanup..."
      sh 'docker compose -f docker-compose.yaml down -v --remove-orphans || true'
      cleanWs()
    }
    success {
      slackSend(message: "✅ Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' succeeded. ${env.BUILD_URL}")
    }
    failure {
      slackSend(message: "❌ Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' failed. ${env.BUILD_URL}")
    }
    aborted {
      slackSend(message: "🚫 Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' was aborted. ${env.BUILD_URL}")
    }
  }
}

// ==================== Helper Methods ====================

def versionCalculationAndTag() {
  withCredentials([usernamePassword(
    credentialsId   : 'gitlab-git-credentials',
    usernameVariable: 'GIT_USER',
    passwordVariable: 'GIT_TOKEN'
  )]) {
    // Fetch tags
    sh '''
      git remote set-url origin https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/workout-gen
      git fetch --tags --quiet || true
    '''
    
    // Calculate version - simplified
    def latestTag = sh(
      script: "git tag --sort=-version:refname | grep -E '^v?[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || echo ''",
      returnStdout: true
    ).trim()

    if (latestTag && latestTag ==~ /^v?(\d+)\.(\d+)\.(\d+)$/) {
      // Extract and increment immediately (no Matcher object stored)
      def parts = (latestTag =~ /^v?(\d+)\.(\d+)\.(\d+)$/)[0]
      def major = parts[1].toInteger()
      def minor = parts[2].toInteger()
      def patch = parts[3].toInteger()
      
      env.CALCULATED_VERSION = "v${major}.${minor}.${patch + 1}"
      echo "${latestTag} → ${env.CALCULATED_VERSION}"
    } else {
      env.CALCULATED_VERSION = "v1.0.0"
      echo "No tags found, starting at v1.0.0"
    }
    
    // Tag and push Git repo
    sh """
      git config user.email "Jenkins@jenkins"
      git config user.name "Jenkins"
      git tag -f ${env.CALCULATED_VERSION}
      git push --force https://\${GIT_USER}:\${GIT_TOKEN}@gitlab.com/yair_portfolio/workout-gen ${env.CALCULATED_VERSION}
    """
    
    echo "✅ Tagged: ${env.CALCULATED_VERSION}"
  }
}

def publishToECR() {
  sh """
    aws ecr get-login-password --region ${AWS_REGION} | \
      docker login --username AWS --password-stdin ${ECR_REGISTRY}

    docker tag ${IMAGE_BACKEND}:${TAG} ${ECR_URI}:backend-${CALCULATED_VERSION}
    docker tag ${IMAGE_BACKEND}:${TAG} ${ECR_URI}:backend-latest
    docker tag ${IMAGE_FRONTEND}:${TAG} ${ECR_URI}:frontend-${CALCULATED_VERSION}
    docker tag ${IMAGE_FRONTEND}:${TAG} ${ECR_URI}:frontend-latest

    docker push ${ECR_URI}:backend-${CALCULATED_VERSION}
    docker push ${ECR_URI}:backend-latest
    docker push ${ECR_URI}:frontend-${CALCULATED_VERSION}
    docker push ${ECR_URI}:frontend-latest
  """
  
  echo "✅ Published to ECR.: ${CALCULATED_VERSION}"
}