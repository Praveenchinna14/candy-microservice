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
   

stage('Push ECR') {
    steps {
        withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding',
             credentialsId: 'aws-cred']
        ]) {
            sh '''
                set +x
                export AWS_DEFAULT_REGION=ap-south-1

                aws sts get-caller-identity

                aws ecr get-login-password \
                  --region ap-south-1 | \
                  docker login \
                  --username AWS \
                  --password-stdin \
                  716397954656.dkr.ecr.ap-south-1.amazonaws.com

                docker push 716397954656.dkr.ecr.ap-south-1.amazonaws.com/candy-user:5
                docker push 716397954656.dkr.ecr.ap-south-1.amazonaws.com/candy-product:5
                docker push 716397954656.dkr.ecr.ap-south-1.amazonaws.com/candy-order:5
            '''
        }
    }
}

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
