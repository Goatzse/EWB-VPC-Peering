variable "aws_region" {
  description = "AWS region for the project"
  type        = string
  default     = "ap-south-1"
}

variable "availability_zone" {
  description = "Availability Zone used by the lab subnets"
  type        = string
  default     = "ap-south-1a"
}

variable "student_name" {
  description = "Student name used in AWS default tags"
  type        = string
}

variable "my_public_ip_cidr" {
  description = "Your current public IPv4 address in CIDR /32 format, e.g. 203.0.113.10/32"
  type        = string
}

variable "public_key" {
  description = "Contents of the SSH public key corresponding to ewb-lab.pem"
  type        = string
}

variable "instance_type" {
  description = "Small x86 EC2 instance type"
  type        = string
  default     = "t3.micro"
}
