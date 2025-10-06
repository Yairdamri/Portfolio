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
      steps {
        sh '''
          set -eu
          echo "Ensure cicd-network exists..."
          docker network inspect cicd-network >/dev/null 2>&1 || docker network create cicd-network

          echo "Compose up (backend + frontend + db) with prebuilt images..."
          docker compose -f docker-compose.yaml up -d

          echo "Waiting for health inside shared network..."
          for i in $(seq 1 60); do
            docker run --rm --network cicd-network curlimages/curl:8.10.1 -fsS http://frontend/health && break || sleep 2
          done

          echo "Running integration tests inside backend container..."
          docker compose exec -T backend sh -lc '
            apk add --no-cache python3 curl coreutils sed grep >/dev/null 2>&1 || true
            chmod +x /app/scripts/integration_test.py
            BASE="http://frontend" python3 /app/scripts/integration_test.py --base http://frontend --skip-build
          '
        '''
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
