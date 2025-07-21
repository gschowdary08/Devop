variable "aws_region" {
  default = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
}

variable "project" {
  default = "jenkins-terraform"
}

variable "db_user" {
  default = "admin"
}

variable "db_password" {
  default = "StrongPass123!"
}
