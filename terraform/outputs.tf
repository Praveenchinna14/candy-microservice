output "instance_public_ip" {
  value = aws_instance.app.public_ip
}
output "ecr_repository_urls" {
  value = { for k, v in aws_ecr_repository.service : k => v.repository_url }
}
