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
    COMPOSE_PROJECT_NAME = "ci-${BUILD_NUMBER}"
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
      steps {
        sh '''
          docker network inspect cicd-network >/dev/null 2>&1 || docker network create cicd-network
          docker compose -f docker-compose.yaml up -d

          chmod +x scripts/integration_check.sh || true
          bash scripts/integration_check.sh
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
      steps {
        sh '''
          set -eu
          // docker network inspect cicd-network >/dev/null 2>&1 || docker network create cicd-network
          // docker compose -f docker-compose.yaml up -d

          chmod +x scripts/e2e_check.sh || true
          bash scripts/e2e_check.sh
        '''
      }

    stage('Tag Version') {
      when {
        expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('hotfix/') || env.BRANCH_NAME?.startsWith('release/') }
      }
      steps {
        script {
          versionCalculation()
          echo "Calculated version: ${env.CALCULATED_VERSION}"
        }
      }
    }

    stage('Publish') {
      when {
        expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('hotfix/') || env.BRANCH_NAME?.startsWith('release/') }
      }
      steps {
        withCredentials([[
          $class       : 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-jenkins-creds'
        ]]) {
          sh '''
            aws ecr get-login-password --region "${AWS_REGION}" \
              | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

            docker tag "${IMAGE_BACKEND}:${TAG}"    "${ECR_URI}:backend-${CALCULATED_VERSION}"
            docker tag "${IMAGE_FRONTEND}:${TAG}"   "${ECR_URI}:frontend-${CALCULATED_VERSION}"
            docker tag "${IMAGE_BACKEND}:${TAG}"    "${ECR_URI}:backend-latest"
            docker tag "${IMAGE_FRONTEND}:${TAG}"   "${ECR_URI}:frontend-latest"

            docker push "${ECR_URI}:backend-${CALCULATED_VERSION}"
            docker push "${ECR_URI}:frontend-${CALCULATED_VERSION}"
            docker push "${ECR_URI}:backend-latest"
            docker push "${ECR_URI}:frontend-latest"
          '''
        }
      }
      post {
        success {
          withCredentials([usernamePassword(
            credentialsId   : 'gitlab-git-credentials',
            usernameVariable: 'GIT_USER',
            passwordVariable: 'GIT_TOKEN'
          )]) {
            sh '''
              set -eu
              git config user.email "yairdamri48@gmail.com"
              git config user.name "yairdamri48"
              git fetch --tags --quiet || true
              git tag -f ${CALCULATED_VERSION}
              git push --force https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/workout-gen ${CALCULATED_VERSION}
            '''
          }
        }
      }
    }

    stage('Deploy') {
      when {
        expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('hotfix/')}
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
            git add charts/workout-stack/values.yaml charts/workout-stack/Chart.yaml
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
      cleanWs()
    }
    success {
      slackSend(message: "✅ Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' succeeded. ${env.BUILD_URL}")
    }
    failure {
      slackSend(message: "❌ Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' failed. ${env.BUILD_URL}")
    }
    // unstable {
    //   slackSend(message: "⚠️ Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' is unstable. ${env.BUILD_URL}")
    // }
    aborted {
      slackSend(message: "🚫 Job '${env.JOB_NAME} [#${env.BUILD_NUMBER}]' was aborted. ${env.BUILD_URL}")
    }
  }
}

def versionCalculation() {
  withCredentials([usernamePassword(
    credentialsId   : 'gitlab-git-credentials',
    usernameVariable: 'GIT_USER',
    passwordVariable: 'GIT_TOKEN'
  )]) {
    sh '''
      set -eu
      git remote set-url origin https://${GIT_USER}:${GIT_TOKEN}@gitlab.com/yair_portfolio/workout-gen
      git fetch --tags --quiet || true
    '''
  }

  def latestTag = sh(
    script: "git tag --sort=-version:refname | grep -E '^v?[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 || true",
    returnStdout: true
  ).trim()

  echo "Latest tag is: ${latestTag}"

  def versionPattern = ~/^v?(\d+)\.(\d+)\.(\d+)$/
  def match = versionPattern.matcher(latestTag)

  if (latestTag && match.matches()) {
    def major = match.group(1).toInteger()
    def minor = match.group(2).toInteger()
    def patch = match.group(3).toInteger()

    // Check if this is a release branch - bump minor and reset patch
    if (env.BRANCH_NAME?.startsWith('release/')) {
      echo "Release branch detected - bumping minor version and resetting patch to 0"
      env.CALCULATED_VERSION = "v${major}.${minor + 1}.0"
    } else {
      echo "Incrementing patch version"
      env.CALCULATED_VERSION = "v${major}.${minor}.${patch + 1}"
    }
  } else {
    echo "No existing tags or unrecognized format. Setting version to v1.0.0"
    env.CALCULATED_VERSION = "v1.0.0"
  }
}
