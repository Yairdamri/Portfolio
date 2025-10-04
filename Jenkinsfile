pipeline {
  agent any
  options {
    ansiColor('xterm')
    timestamps()
    disableConcurrentBuilds()
  }
  environment {
    IMAGE = 'workout-app'
    TAG = "${BRANCH_NAME}-${BUILD_NUMBER}"
    // Provide these as Jenkins credentials or env vars
    AWS_ACCOUNT_ID = '273809175099'
    AWS_REGION = 'ap-south-1'
    ECR_REPOSITORY = '273809175099.dkr.ecr.ap-south-1.amazonaws.com/dev_protfolio'
    DOCKER_BUILDKIT = '1'
  }
  stages {
    stage('Source') {
      steps {
        cleanWs()
        checkout scm
        sh 'git rev-parse --short HEAD'
      }
    }

    stage('Build') {
      steps {
        sh 'python -V || true'
      }
    }

    stage('Unit Tests') {
      steps {
        sh 'docker run --rm -v "$PWD:/app" -w /app python:3.11 bash -lc "pip install -r requirements.txt && mkdir -p reports && pytest -q --maxfail=1 --disable-warnings --junitxml=reports/unit-tests.xml"'
      }
    }

    stage('Package Docker Image') {
      steps {
        sh 'docker build -t ${IMAGE}:${TAG} .'
      }
    }

    stage('Integration: Up (docker-compose)') {
      when { expression { return env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') } }
      steps {
        sh 'docker-compose -f docker-compose.yaml up -d --build'
        sh 'echo "Waiting for API to be healthy..."'
        sh 'for i in {1..60}; do curl -fsS http://localhost/health && break || sleep 2; done'
      }
    }

    stage('Integration: API Tests') {
      when { expression { return env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') } }
      steps {
        sh 'chmod +x scripts/integration_test.sh && BASE="http://localhost" bash scripts/integration_test.sh'
      }
      post {
        always {
          sh 'docker-compose -f docker-compose.yaml logs nginx || true'
        }
      }
    }

    stage('Integration: Down') {
      when { expression { return env.BRANCH_NAME == 'main' || env.BRANCH_NAME?.startsWith('feature/') } }
      steps {
        sh 'docker-compose -f docker-compose.yaml down -v || true'
      }
    }

    stage('Tag Release') {
      when { branch 'main' }
      steps {
        sh '''
          git config user.name "jenkins"
          git config user.email "jenkins@local"
          git tag v${BUILD_NUMBER} || true
          git push origin v${BUILD_NUMBER} || true
        '''
      }
    }

    stage('Publish to ECR') {
      when { branch 'main' }
      steps {
        sh '''
          if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ] || [ -z "$ECR_REPOSITORY" ]; then
            echo "ECR env missing; skipping publish"; exit 0; fi
         ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
         aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin $ECR_REGISTRY
          docker tag ${IMAGE}:${TAG} $ECR_REGISTRY/${ECR_REPOSITORY}:${TAG}
          docker push $ECR_REGISTRY/${ECR_REPOSITORY}:${TAG}
        '''
      }
    }

    stage('Deploy (GitOps)') {
      when { branch 'main' }
      steps {
        sh '''
          if [ -n "$GITOPS_REPO" ]; then
            echo "Update GitOps repo to ${TAG} (placeholder)"
            # Implement according to your GitOps flow (Flux/Argo CD)
          else
            echo "GITOPS_REPO not set; skipping deploy"
          fi
        '''
      }
    }
  }
  post {
    success {
      script {
        def msg = "✅ ${env.JOB_NAME} #${env.BUILD_NUMBER} (${env.BRANCH_NAME}) succeeded. Tag: ${env.TAG}"
        if (env.SLACK_CHANNEL) { slackSend channel: env.SLACK_CHANNEL, color: 'good', message: msg } else { slackSend color: 'good', message: msg }
      }
    }
    failure {
      script {
        def msg = "❌ ${env.JOB_NAME} #${env.BUILD_NUMBER} (${env.BRANCH_NAME}) failed. See ${env.BUILD_URL}"
        if (env.SLACK_CHANNEL) { slackSend channel: env.SLACK_CHANNEL, color: 'danger', message: msg } else { slackSend color: 'danger', message: msg }
      }
    }
    unstable {
      script {
        def msg = "⚠️ ${env.JOB_NAME} #${env.BUILD_NUMBER} (${env.BRANCH_NAME}) unstable. See ${env.BUILD_URL}"
        if (env.SLACK_CHANNEL) { slackSend channel: env.SLACK_CHANNEL, color: 'warning', message: msg } else { slackSend color: 'warning', message: msg }
      }
    }
    always {
      archiveArtifacts artifacts: 'scripts/**, docker-compose.yaml', onlyIfSuccessful: false
      junit 'reports/**/*.xml'
      sh 'docker system prune -f || true'
      cleanWs()
    }
  }
}
