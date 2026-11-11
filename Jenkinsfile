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

                REGISTRY=716397954656.dkr.ecr.ap-south-1.amazonaws.com
                TAG=${BUILD_NUMBER}

                aws ecr get-login-password \
                  --region ap-south-1 | \
                  docker login \
                  --username AWS \
                  --password-stdin $REGISTRY

                echo "Pushing Docker images with tag: $TAG"

                docker tag local/candy-user:$TAG $REGISTRY/candy-user:$TAG
                docker tag local/candy-product:$TAG $REGISTRY/candy-product:$TAG
                docker tag local/candy-order:$TAG $REGISTRY/candy-order:$TAG

                docker push $REGISTRY/candy-user:$TAG
                docker push $REGISTRY/candy-product:$TAG
                docker push $REGISTRY/candy-order:$TAG
            '''
        }
    }
}


stage('Deploy') {
    when {
        branch 'main'
    }
    steps {
        withCredentials([
            sshUserPrivateKey(
                credentialsId: 'ec2-ssh-key',
                keyFileVariable: 'SSH_KEY',
                usernameVariable: 'SSH_USER'
            )
        ]) {
            sh '''
                set +x

                REGISTRY=716397954656.dkr.ecr.ap-south-1.amazonaws.com
                TAG=${BUILD_NUMBER}
                EC2_HOST=13.201.23.71

                ssh -i "$SSH_KEY" \
                    -o StrictHostKeyChecking=no \
                    "$SSH_USER@$EC2_HOST" "
                        set -e
                        cd /tmp/candy-microservice

                        aws ecr get-login-password --region ap-south-1 |
                        sudo docker login --username AWS --password-stdin $REGISTRY

                        export ECR_REGISTRY=$REGISTRY
                        export IMAGE_TAG=$TAG

                        sudo -E docker compose pull
                        sudo -E docker compose up -d --no-build

                        sudo docker compose ps

                        curl -f http://localhost/health
                        curl -f http://localhost/users/health/
                        curl -f http://localhost/products/health/
                        curl -f http://localhost/orders/health/
                    "
            '''
        }
    }
} }
}
  post { always { sh 'docker compose down --remove-orphans || true' } 
}
