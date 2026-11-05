data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
resource "aws_security_group" "app" {
  name_prefix = "candystore-"
  description = "CandyStore web host"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_iam_role" "ec2_ecr_read" {
  name = "candystore-ec2-ecr-read"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_ecr_read.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_instance_profile" "app" {
  name = "candystore-ec2-profile"
  role = aws_iam_role.ec2_ecr_read.name
}
resource "aws_ecr_repository" "service" {
  for_each             = toset(["candy-user", "candy-product", "candy-order"])
  name                 = each.key
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
resource "aws_instance" "app" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  subnet_id            = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.app.name
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker awscli
    systemctl enable --now docker
    usermod -aG docker ec2-user
    mkdir -p /opt/candystore
  EOF
  tags = {
    Name = "candystore-microservices"
  }
}
