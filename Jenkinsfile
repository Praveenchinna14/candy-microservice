pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }
  environment { AWS_REGION = 'ap-south-1'; IMAGE_TAG = "${BUILD_NUMBER}" }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Validate') { steps { sh 'docker compose config -q' } }
    stage('Build') { steps {
      sh 'docker build -t candy-user:${IMAGE_TAG} ./user-service'
      sh 'docker build -t candy-product:${IMAGE_TAG} ./product-service'
      sh 'docker build -t candy-order:${IMAGE_TAG} ./order-service'
    } }
    stage('Local smoke test') { steps {
      sh 'docker compose up -d --build; sleep 15; curl -fsS http://localhost/health; curl -fsS http://localhost/users/health/; docker compose down'
    } }
    stage('Push ECR') { steps {
      withAWS(credentials: 'aws-cred', region: "${AWS_REGION}") {
        sh '''
          ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
          REGISTRY=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
          aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY
          for name in candy-user candy-product candy-order; do
            docker tag $name:${IMAGE_TAG} $REGISTRY/$name:${IMAGE_TAG}
            docker push $REGISTRY/$name:${IMAGE_TAG}
          done
        '''
      }
    } }
   stage('Deploy') {
    when {
        branch 'main'
    }

    steps {
        sshagent(['ec2-ssh-key']) {
            sh '''
                ssh -o StrictHostKeyChecking=no ubuntu@YOUR_EC2_PUBLIC_IP "
                    echo 'Connected to EC2 successfully'
                    docker --version
                "
            '''
        }
    }
} }
  }
  post { always { sh 'docker compose down --remove-orphans || true' } 
}
