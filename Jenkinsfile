pipeline {
  agent any
  options {
    timestamps()
    disableConcurrentBuilds()
  }
  environment {
    DOCKER_BUILDKIT = '1'
    IMAGE_BACKEND = 'workout-backend'
    IMAGE_FRONTEND = 'workout-frontend'
    TAG = "${BRANCH_NAME}-${BUILD_NUMBER}"
    // Ensure predictable compose network name: ${COMPOSE_PROJECT_NAME}_default
    COMPOSE_PROJECT_NAME = "ci-${BUILD_NUMBER}"
  }
  stages {
    stage('Checkout') {
      steps {
        cleanWs()
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh 'docker compose -f docker-compose.yaml build'
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          set -eu
          echo "Building lightweight test image..."
          docker build --target test -t backend-test:ci .
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
          echo "Packaging Docker images as artifacts..."
          # Build and tag images explicitly (simple and reproducible)
          docker build -t ${IMAGE_BACKEND}:${TAG} .
          docker build -t ${IMAGE_FRONTEND}:${TAG} ./frontend
          # Save images to tar files for portability
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
          echo "Compose up (backend + frontend + db)..."
          docker compose -f docker-compose.yaml up -d --build

          echo "Waiting for health inside shared network (frontend reachable from Jenkins)..."
          for i in $(seq 1 60); do docker run --rm --network cicd-network curlimages/curl:8.10.1 -fsS http://frontend/health && break || sleep 2; done

          echo "Running integration tests inside backend container (via nginx)..."
          docker compose exec -T backend sh -lc 'apk add --no-cache bash curl coreutils sed grep >/dev/null 2>&1 || true; chmod +x /app/scripts/integration_test.sh; BASE="http://frontend" bash /app/scripts/integration_test.sh'
        '''
      }
    }
  }
  post {
    always {
      // Clean only resources created by this compose project
      sh 'docker compose -f docker-compose.yaml down -v --remove-orphans || true'
      // Optionally clean dangling images only (safe):
      // sh 'docker image prune -f || true'
      archiveArtifacts artifacts: 'artifacts/*.tar', onlyIfSuccessful: false
      cleanWs()
    }
  }
}
