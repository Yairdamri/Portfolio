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

    // stage('Build Test Image') {
    //   steps {
    //     sh '''
    //       set -eu
    //       echo "Building lightweight test image..."
    //       docker build -f Dockerfile.test -t backend-test:ci .
    //     '''
    //   }
    // }

    // stage('Unit Tests') {
    //   steps {
    //     sh '''
    //       set -eu
    //       echo "Running unit tests..."
    //       mkdir -p reports
    //       docker run --rm -v "$PWD/reports:/app/reports" backend-test:ci
    //     '''
    //   }
    // }

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

    // stage('Integration Test') {
    //   when {
    //     expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') }
    //   }
    //   steps {
    //     sh '''
    //       set -eu
    //       echo "Starting integration test environment..."
    //       docker network inspect cicd-network >/dev/null 2>&1 || docker network create cicd-network
    //       docker compose -f docker-compose.yaml up -d

    //       echo "Running integration tests inside backend container..."
    //       docker compose exec -T backend sh -lc '
    //         python3 --version >/dev/null 2>&1 || apk add --no-cache python3 >/dev/null
    //         python3 -m pip install --no-cache-dir pytest >/dev/null 2>&1 || true
    //         PYTHONPATH=/app pytest -q scripts/test_integration_api.py
    //       '
    //     '''
    //   }
    //   post {
    //     always {
    //       sh '''
    //         echo "Cleaning up integration test environment..."
    //         docker compose -f docker-compose.yaml down -v --remove-orphans >/dev/null 2>&1 || true
    //       '''
    //     }
    //   }
    // }

    // stage('E2E Test') {
    //   when {
    //     expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') }
    //   }
    //   steps {
    //     sh '''
    //       set -eu
    //       echo "Starting E2E environment..."
    //       docker network inspect cicd-network >/dev/null 2>&1 || docker network create cicd-network
    //       docker compose -f docker-compose.yaml up -d

    //       echo "Running E2E script against live stack..."
    //       docker compose exec -T backend sh -lc '
    //         python3 --version >/dev/null 2>&1 || apk add --no-cache python3 >/dev/null
    //         python3 /app/scripts/e2e_test.py --base http://frontend --skip-build
    //       '
    //     '''
    //   }
    //   post {
    //     always {
    //       sh '''
    //         echo "Cleaning up E2E environment..."
    //         docker compose -f docker-compose.yaml down -v --remove-orphans >/dev/null 2>&1 || true
    //       '''
    //     }
    //   }
    // }

    stage('Tag Release') {
      when {
        branch 'main'
      }
      steps {
        script {
          env.CALCULATED_VERSION = versionCalculation()
          echo "Calculated version: ${env.CALCULATED_VERSION}"
        }
        withCredentials([usernamePassword(
          credentialsId: 'gitlab-git-credentials',
          usernameVariable: 'GIT_USER',
          passwordVariable: 'GIT_TOKEN'
        )]) {
          sh '''
            set -eu
            git config user.email "yairdamri48@gmail.com"
            git config user.name "yairdamri48"
            git tag ${CALCULATED_VERSION}
            git push https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/workout-gen ${CALCULATED_VERSION}
          '''
        }
      }
    }

    stage('Publish') {
      when { branch 'main' }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-jenkins-creds'
        ]]) {
          sh '''
            set -eu
            docker run --rm \
              -e AWS_ACCESS_KEY_ID \
              -e AWS_SECRET_ACCESS_KEY \
              -e AWS_SESSION_TOKEN \
              -e AWS_REGION=${AWS_REGION} \
              amazon/aws-cli \
              ecr get-login-password --region ${AWS_REGION} \
              | docker login --username AWS --password-stdin ${ECR_REGISTRY}

            docker tag ${IMAGE_BACKEND}:${TAG} ${ECR_URI}:backend-${CALCULATED_VERSION}
            docker tag ${IMAGE_FRONTEND}:${TAG} ${ECR_URI}:frontend-${CALCULATED_VERSION}
            docker tag ${IMAGE_BACKEND}:${TAG} ${ECR_URI}:backend-latest
            docker tag ${IMAGE_FRONTEND}:${TAG} ${ECR_URI}:frontend-latest

            docker push ${ECR_URI}:backend-${CALCULATED_VERSION}
            docker push ${ECR_URI}:frontend-${CALCULATED_VERSION}
            docker push ${ECR_URI}:backend-latest
            docker push ${ECR_URI}:frontend-latest
          '''
        }
      }
    }

    stage('Deploy') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'gitlab-git-credentials',
          usernameVariable: 'GIT_USER',
          passwordVariable: 'GIT_TOKEN'
        )]) {
          sh '''
            set -eu

            BACKEND_TAG=backend-${TAG}
            FRONTEND_TAG=frontend-${TAG}

            rm -rf k8s-infra
            git clone https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/k8s-infra.git
            cd k8s-infra

            sed -i "s/tag: backend-.*/tag: ${BACKEND_TAG}/" charts/workout-stack/values.yaml
            sed -i "s/tag: frontend-.*/tag: ${FRONTEND_TAG}/" charts/workout-stack/values.yaml
            sed -i "s/^appVersion:.*/appVersion: ${CALCULATED_VERSION}/" k8s/charts/workout-stack/Chart.yaml

            git config user.email "ci@jenkins"
            git config user.name "Jenkins"
            git add k8s/charts/workout-stack/values.yaml k8s/charts/workout-stack/Chart.yaml
            if git diff --cached --quiet; then
              echo "No changes to commit."
            else
              git commit -m "ci: deploy ${BACKEND_TAG}/${FRONTEND_TAG} (${CALCULATED_VERSION}) [skip ci]"
              git push https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/k8s-infra.git main
            fi
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
    success {
      slackSend(message: "✅ Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' succeeded. ${env.BUILD_URL}")
    }
    failure {
      slackSend(message: "❌ Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' failed. ${env.BUILD_URL}")
    }
    unstable {
      slackSend(message: "⚠️ Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' is unstable. ${env.BUILD_URL}")
    }
    aborted {
      slackSend(message: "🚫 Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' was aborted. ${env.BUILD_URL}")
    }
  }
}

def versionCalculation() {
  String newVersion = ''
  withCredentials([usernamePassword(
    credentialsId: 'gitlab-git-credentials',
    usernameVariable: 'GIT_USER',
    passwordVariable: 'GIT_TOKEN'
  )]) {
    sh '''
      set -eu
      git remote set-url origin https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/workout-gen
      git fetch --tags --quiet || true
    '''
    def latestTag = sh(returnStdout: true, script: 'git tag | sort -V | tail -n1').trim()
    if (latestTag) {
      def matcher = latestTag =~ /^v?(\\d+)\\.(\\d+)\\.(\\d+)$/
      if (matcher.matches()) {
        int major = matcher[0][1].toInteger()
        int minor = matcher[0][2].toInteger()
        int patch = matcher[0][3].toInteger() + 1
        newVersion = "v${major}.${minor}.${patch}"
      } else {
        newVersion = "v1.0.0"
      }
    } else {
      newVersion = "v1.0.0"
    }
  }
  return newVersion
}
