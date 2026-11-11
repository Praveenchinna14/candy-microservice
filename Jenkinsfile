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
                        credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        set +x

                        EC2_HOST=13.201.23.71

                        ssh -i "$SSH_KEY" \
                            -o StrictHostKeyChecking=no \
                            "$SSH_USER@$EC2_HOST" "
                                set -e

                                cd /tmp/candy-microservice

                                echo 'Logging in to AWS ECR'

                                aws ecr get-login-password \
                                  --region ap-south-1 |
                                  sudo docker login \
                                  --username AWS \
                                  --password-stdin ${ECR_REGISTRY}

                                echo 'Deploying image tag: ${IMAGE_TAG}'

                                sudo env \
                                  ECR_REGISTRY=${ECR_REGISTRY} \
                                  IMAGE_TAG=${IMAGE_TAG} \
                                  docker compose pull

                                sudo env \
                                  ECR_REGISTRY=${ECR_REGISTRY} \
                                  IMAGE_TAG=${IMAGE_TAG} \
                                  docker compose up -d --no-build

                                echo 'Checking containers'

                                sudo docker compose ps

                                echo 'Checking application health'

                                curl -f http://localhost/health

                                curl -f http://localhost/users/health/

                                curl -f http://localhost/products/health/

                                curl -f http://localhost/orders/health/

                                echo 'Deployment successful'
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
