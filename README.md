# CandyStore Microservices – DevOps CI/CD Project

Starter scaffold for the assignment: Django services, Docker Compose, Nginx, Jenkins, AWS ECR/EC2, Terraform, Prometheus, Node Exporter and Grafana.

**Important:** the original public CandyStore repository is a Django monolith. This scaffold creates three Django service shells; it does not automatically migrate the original models, views, templates or data. The service boundaries below are proposed and must be aligned with the actual source code.

## Architecture and service boundaries
- **User Service:** registration, login, profile and user-related endpoints.
- **Product Service:** candy catalog, categories, prices and inventory.
- **Order Service:** cart/order creation, order history, totals and status.
- **Nginx:** public gateway on port 80, routing `/users/`, `/products/`, `/orders/`.
- **Jenkins:** checkout, compose validation, Docker build, smoke test, ECR push and EC2 deployment template.
- **Terraform:** one EC2, three ECR repositories, security group and EC2 ECR read-only IAM role.
- **Monitoring:** Prometheus, Node Exporter and Grafana. Host metrics are configured; Django application metrics need instrumentation.

## Layout
```text
CandyStore/
├── user-service/                 # Django user API
├── product-service/              # Django product API
├── order-service/                # Django order API
├── nginx/nginx.conf               # Reverse proxy
├── terraform/                     # EC2, ECR, IAM, security group
├── monitoring/                    # Prometheus, Node Exporter, Grafana
├── docker-compose.yml             # App stack
├── Jenkinsfile                    # CI/CD pipeline template
├── .env.example
└── README.md
```
Each service contains `manage.py`, a Django project package, `requirements.txt`, and a Dockerfile. Each exposes `/health/` and a starter JSON root endpoint.

## Run locally
Requirements: Git, Docker Engine/Desktop and Docker Compose v2.
```bash
docker compose up --build -d
docker compose ps
curl http://localhost/health
curl http://localhost/users/health/
curl http://localhost/products/health/
curl http://localhost/orders/health/
docker compose logs -f
docker compose down
```

## Terraform deployment
Requirements: AWS CLI configured, Terraform >=1.5, an existing EC2 key pair, and a default VPC with a subnet.
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Set ssh_cidr to your own public IP/32 and key_name to your EC2 key pair
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
```
The Terraform template defaults to `ap-south-1`, selects the first subnet in the default VPC, creates one EC2 and three ECR repositories. The security group exposes HTTP and restricts SSH to `ssh_cidr`. The EC2 role is read-only for ECR. User data installs Docker and creates `/opt/candystore`; it does not finish the application deployment or install the Compose plugin. Review all resources and costs before applying.

## Jenkins configuration
Install Pipeline, Git, Docker-capable agent, SSH Agent and AWS integration (the Jenkinsfile uses `withAWS`). Configure credentials named `aws-jenkins-credentials` and `candystore-ec2-ssh`, plus `DEPLOY_HOST`. Give Jenkins ECR push permissions and EC2 only ECR pull permissions. Configure a GitHub webhook. Store production environment values in Jenkins credentials or on EC2; never commit `.env.production` or cloud keys. Complete the deploy stage to copy the Compose/Nginx files and supply the correct ECR registry/tag to Compose before using it as a production pipeline.

## Monitoring
```bash
cd monitoring
docker compose -f docker-compose.monitoring.yml up -d
```
Prometheus uses port 9090, Grafana 3000; do not expose either publicly. Set a Grafana admin password and access through an SSH tunnel/VPN or restricted source CIDR. Node Exporter scrapes host metrics. Add Django Prometheus instrumentation and targets for application metrics.

## Four-day implementation plan
| Day | Tasks | Evidence |
|---|---|---|
| 1 | Inspect monolith models/views/URLs; extract services; Dockerfiles, Compose, Nginx | Local endpoint curls and healthy containers |
| 2 | Terraform EC2/ECR/IAM/security group; test SSH and ECR pull | Terraform output, EC2 and ECR screenshots |
| 3 | Jenkins webhook, tests, build, tag, push, deploy and rollback | Jenkins console, ECR images, deployment verification |
| 4 | Prometheus/Grafana, failure simulation, logs, docs and cleanup | Dashboards, alert/log evidence, README |

## Important implementation and safety notes
- Do not share the original SQLite database among independently deployed services. Give each service separate data ownership and a migration plan.
- Implement real API views, models, validation, authentication, tests and migrations; starter endpoints are not the finished business application.
- Never commit AWS keys, SSH keys, `.env`, Terraform state or production secrets.
- Restrict SSH to your IP; keep monitoring endpoints private.
- Configure AWS Budget alerts and run `terraform destroy` after collecting evidence, after checking the correct state/workspace.
- Kubernetes, EKS, RDS, NAT Gateway and load balancer are intentionally not included; this assignment design uses one EC2 host and Docker Compose.
