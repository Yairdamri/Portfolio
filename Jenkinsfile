pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    DOCKER_BUILDKIT       = '1'
    IMAGE_BACKEND         = 'workout-backend'
    IMAGE_FRONTEND        = 'workout-frontend'
    TAG                   = "${BRANCH_NAME}-${BUILD_NUMBER}"
    COMPOSE_PROJECT_NAME  = "ci-${BUILD_NUMBER}"
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
        expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') }
      }
      steps {
        sh '''
          set -eu
          echo "Starting integration test environment..."
          docker network inspect cicd-network >/dev/null 2>&1 || docker network create cicd-network
          docker compose -f docker-compose.yaml up -d

          echo "Running integration tests inside backend container..."
          docker compose exec -T backend sh -lc '
            python3 --version >/dev/null 2>&1 || apk add --no-cache python3 >/dev/null
            python3 -m pip install --no-cache-dir pytest >/dev/null 2>&1 || true
            PYTHONPATH=/app pytest -q scripts/test_integration_api.py
          '
        '''
      }
      post {
        always {
          sh '''
            echo "Cleaning up integration test environment..."
            docker compose -f docker-compose.yaml down -v --remove-orphans >/dev/null 2>&1 || true
          '''
        }
      }
    }
  }

  post {
    always {
      echo "Final cleanup..."
      sh 'docker compose -f docker-compose.yaml down -v --remove-orphans || true'
      archiveArtifacts artifacts: 'artifacts/*.tar', onlyIfSuccessful: false
      cleanWs()
    }
  }
}
