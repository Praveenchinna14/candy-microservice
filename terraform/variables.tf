variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "ssh_cidr" {
  type        = string
  description = "Your public IP in CIDR format, e.g. 203.0.113.10/32"
}
variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}
