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
    AWS_REGION            = 'ap-south-1'
    ECR_REGISTRY          = '273809175099.dkr.ecr.ap-south-1.amazonaws.com'
    ECR_URI               = '273809175099.dkr.ecr.ap-south-1.amazonaws.com/dev_protfolio'
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

    stage('E2E Test') {
      when {
        expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') }
      }
      steps {
        sh '''
          set -eu
          echo "Starting E2E environment..."
          docker network inspect cicd-network >/dev/null 2>&1 || docker network create cicd-network
          docker compose -f docker-compose.yaml up -d

          echo "Running E2E script against live stack..."
          docker compose exec -T backend sh -lc '
            python3 --version >/dev/null 2>&1 || apk add --no-cache python3 >/dev/null
            python3 /app/scripts/e2e_test.py --base http://frontend --skip-build
          '
        '''
      }
      post {
        always {
          sh '''
            echo "Cleaning up E2E environment..."
            docker compose -f docker-compose.yaml down -v --remove-orphans >/dev/null 2>&1 || true
          '''
        }
      }
    }

    stage('Tag Release') {
  when { branch 'main' }
  steps {
    withCredentials([usernamePassword(credentialsId: 'gitlab-git-credentials',
                                      usernameVariable: 'GIT_USER',
                                      passwordVariable: 'GIT_TOKEN')]) {
      sh """
        git config user.email "yairdamri48@gmail.com"
        git config user.name "yairdamri48"
        git tag v${BUILD_NUMBER}
        git push https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/workout-gen v${BUILD_NUMBER}
      """
    }
  }
}


    stage('Publish') {
      when {
        branch 'main'
      }
      steps {
        sh '''
          set -eu
          echo "Authenticating with AWS ECR..."
          aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

          echo "Tagging images for ECR..."
          docker tag ${IMAGE_BACKEND}:${TAG} ${ECR_URI}:backend-${TAG}
          docker tag ${IMAGE_FRONTEND}:${TAG} ${ECR_URI}:frontend-${TAG}

          echo "Pushing images to ECR..."
          docker push ${ECR_URI}:backend-${TAG}
          docker push ${ECR_URI}:frontend-${TAG}
        '''
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
