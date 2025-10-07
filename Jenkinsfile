pipeline {
  agent any
  options {
    timestamps()
    disableConcurrentBuilds()
  }
  environment {
    DOCKER_BUILDKIT = '1'
    IMAGE_BACKEND   = 'workout-backend'
    IMAGE_FRONTEND  = 'workout-frontend'
    TAG             = "${BRANCH_NAME}-${BUILD_NUMBER}"
    COMPOSE_PROJECT_NAME = "ci-${BUILD_NUMBER}"
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
        sh '''
          set -eu
          echo "Building lightweight test image..."
          docker build --target test -t backend-test:ci .
        '''
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          set -eu
          echo "Running unit tests..."
          mkdir -p reports
          docker run --rm -v "$PWD/reports:/app/reports" backend-test:ci
        '''
      }
    }

    stage('Package') {
      steps {
        sh '''
          set -eu
          echo "Building production Docker images..."
          docker build -t ${IMAGE_BACKEND}:${TAG} .
          docker build -t ${IMAGE_FRONTEND}:${TAG} ./frontend

          echo "Saving Docker images as artifacts..."
          mkdir -p artifacts
          docker save ${IMAGE_BACKEND}:${TAG} -o artifacts/${IMAGE_BACKEND}-${TAG}.tar
          docker save ${IMAGE_FRONTEND}:${TAG} -o artifacts/${IMAGE_FRONTEND}-${TAG}.tar
        '''
      }
    }

    stage('Integration Test') {
      when {
        expression { return env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') }
      }
      agent {
        docker {
          image 'docker:24.0.2-dind'
          args '--privileged'
        }
      }
      steps {
        sh '''
          set -eu
          echo "Waiting for Docker daemon..."
          for i in $(seq 1 20); do
            if docker info >/dev/null 2>&1; then
              break
            fi
            sleep 2
          done

          echo "Installing Python runtime for integration script..."
          apk add --no-cache python3 >/dev/null

          echo "Preparing external network for compose..."
          docker network create cicd-network >/dev/null 2>&1 || true

          echo "Running integration script via docker-in-docker..."
          python3 scripts/integration_test.py --base http://localhost
        '''
      }
      post {
        always {
          sh '''
            docker compose -f docker-compose.yaml down -v --remove-orphans >/dev/null 2>&1 || true
          '''
        }
      }
    }
  }
  post {
    always {
      sh 'docker compose -f docker-compose.yaml down -v --remove-orphans || true'
      archiveArtifacts artifacts: 'artifacts/*.tar', onlyIfSuccessful: false
      cleanWs()
    }
  }
}
