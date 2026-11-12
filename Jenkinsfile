pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_DEFAULT_REGION = 'ap-south-1'
        ECR_REGISTRY = '716397954656.dkr.ecr.ap-south-1.amazonaws.com'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate') {
            steps {
                sh 'docker compose config -q'
            }
        }

        stage('Build') {
            steps {
                sh '''
                    docker build -t local/candy-user:${IMAGE_TAG} ./user-service

                    docker build -t local/candy-product:${IMAGE_TAG} ./product-service

                    docker build -t local/candy-order:${IMAGE_TAG} ./order-service
                '''
            }
        }

        stage('Push ECR') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-cred']
                ]) {
                    sh '''
                        set +x

                        aws ecr get-login-password \
                          --region ${AWS_REGION} |
                          docker login \
                          --username AWS \
                          --password-stdin ${ECR_REGISTRY}

                        echo "Pushing images with tag: ${IMAGE_TAG}"

                        docker tag local/candy-user:${IMAGE_TAG} \
                          ${ECR_REGISTRY}/candy-user:${IMAGE_TAG}

                        docker tag local/candy-product:${IMAGE_TAG} \
                          ${ECR_REGISTRY}/candy-product:${IMAGE_TAG}

                        docker tag local/candy-order:${IMAGE_TAG} \
                          ${ECR_REGISTRY}/candy-order:${IMAGE_TAG}

                        docker push ${ECR_REGISTRY}/candy-user:${IMAGE_TAG}

                        docker push ${ECR_REGISTRY}/candy-product:${IMAGE_TAG}

                        docker push ${ECR_REGISTRY}/candy-order:${IMAGE_TAG}
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
                credentialsId: 'ssh-cred',
                keyFileVariable: 'SSH_KEY',
                usernameVariable: 'SSH_USER'
            )
        ]) {
            sh '''
                set -e
                set +x

                EC2_HOST=13.201.76.148
                DEPLOY_DIR=/tmp/candy-microservice

                echo "Creating deployment directory on EC2"

                ssh -i "$SSH_KEY" \
                    -o StrictHostKeyChecking=no \
                    "$SSH_USER@$EC2_HOST" \
                    "mkdir -p $DEPLOY_DIR/nginx"

                echo "Copying deployment files to EC2"

                scp -i "$SSH_KEY" \
                    -o StrictHostKeyChecking=no \
                    docker-compose.yml \
                    "$SSH_USER@$EC2_HOST:$DEPLOY_DIR/"

                scp -i "$SSH_KEY" \
                    -o StrictHostKeyChecking=no \
                    nginx/nginx.conf \
                    "$SSH_USER@$EC2_HOST:$DEPLOY_DIR/nginx/"

                echo "Deploying image tag: ${IMAGE_TAG}"

                ssh -i "$SSH_KEY" \
                    -o StrictHostKeyChecking=no \
                    "$SSH_USER@$EC2_HOST" "
                        set -e

                        cd $DEPLOY_DIR

                        echo 'Logging into AWS ECR'

                        aws ecr get-login-password \
                          --region ${AWS_REGION} |
                          sudo docker login \
                          --username AWS \
                          --password-stdin ${ECR_REGISTRY}

                        echo 'Pulling latest application images'

                        sudo env \
                          ECR_REGISTRY=${ECR_REGISTRY} \
                          IMAGE_TAG=${IMAGE_TAG} \
                          docker compose pull

                        echo 'Starting CandyStore containers'

                        sudo env \
                          ECR_REGISTRY=${ECR_REGISTRY} \
                          IMAGE_TAG=${IMAGE_TAG} \
                          docker compose up -d --no-build

                        echo 'Checking container status'

                        sudo docker compose ps

                        echo 'Deployment completed'
                    "
            '''
        }
    }
}
  }

    post {
        success {
            echo 'CandyStore CI/CD pipeline completed successfully!'
        }

        failure {
            echo 'CandyStore CI/CD pipeline failed. Check the stage logs.'
        }
    }
}
