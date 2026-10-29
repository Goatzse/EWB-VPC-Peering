terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "EWB-VPC-Peering"
      Student = var.student_name
    }
  }
}

# -----------------------------
# VPC A
# -----------------------------
resource "aws_vpc" "vpc_a" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ewb-vpc-a"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "ewb-public-a"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "ewb-private-a"
  }
}

# -----------------------------
# VPC B
# -----------------------------
resource "aws_vpc" "vpc_b" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ewb-vpc-b"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.vpc_b.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "ewb-private-b"
  }
}

# -----------------------------
# Internet Gateway for VPC A
# -----------------------------
resource "aws_internet_gateway" "igw_a" {
  vpc_id = aws_vpc.vpc_a.id

  tags = {
    Name = "ewb-igw-a"
  }
}

# -----------------------------
# Route tables
# -----------------------------
resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.vpc_a.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_a.id
  }

  tags = {
    Name = "ewb-rt-a-public"
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.vpc_a.id

  tags = {
    Name = "ewb-rt-a-private"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.vpc_b.id

  tags = {
    Name = "ewb-rt-b-private"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

# -----------------------------
# VPC Peering
# -----------------------------
resource "aws_vpc_peering_connection" "a_b" {
  vpc_id      = aws_vpc.vpc_a.id
  peer_vpc_id = aws_vpc.vpc_b.id
  auto_accept = true

  tags = {
    Name = "ewb-a-b-peer"
  }
}

# VPC A private route -> VPC B
resource "aws_route" "private_a_to_b" {
  route_table_id            = aws_route_table.private_a.id
  destination_cidr_block    = "10.20.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b.id
}

# VPC B private route -> VPC A
resource "aws_route" "private_b_to_a" {
  route_table_id            = aws_route_table.private_b.id
  destination_cidr_block    = "10.10.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b.id
}

# Public subnet route table also needs the peer route so that
# traffic from the bastion can reach private VPC B.
resource "aws_route" "public_a_to_b" {
  route_table_id            = aws_route_table.public_a.id
  destination_cidr_block    = "10.20.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b.id
}

# -----------------------------
# Security groups
# -----------------------------
resource "aws_security_group" "bastion" {
  name        = "ewb-sg-bastion"
  description = "SSH access to bastion from student's public IP"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "SSH from student's public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_public_ip_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-bastion"
  }
}

resource "aws_security_group" "app_a" {
  name        = "ewb-sg-app-a"
  description = "Private App-A security group"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.10/32"]
  }

  ingress {
    description = "ICMP from App-B"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.20.1.10/32"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-app-a"
  }
}

resource "aws_security_group" "app_b" {
  name        = "ewb-sg-app-b"
  description = "Private App-B security group"
  vpc_id      = aws_vpc.vpc_b.id

  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.10/32"]
  }

  ingress {
    description = "ICMP from App-A"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.10.2.10/32"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ewb-sg-app-b"
  }
}

# -----------------------------
# EC2 key pair
# -----------------------------
resource "aws_key_pair" "ewb_lab" {
  key_name   = "ewb-lab"
  public_key = var.public_key

  tags = {
    Name = "ewb-lab"
  }
}

# Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# -----------------------------
# EC2 instances
# -----------------------------
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_a.id
  private_ip                  = "10.10.1.10"
  key_name                    = aws_key_pair.ewb_lab.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    Name = "ewb-bastion"
  }
}

resource "aws_instance" "app_a" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_a.id
  private_ip             = "10.10.2.10"
  key_name               = aws_key_pair.ewb_lab.key_name
  vpc_security_group_ids = [aws_security_group.app_a.id]

  tags = {
    Name = "ewb-app-a"
  }
}

resource "aws_instance" "app_b" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_b.id
  private_ip             = "10.20.1.10"
  key_name               = aws_key_pair.ewb_lab.key_name
  vpc_security_group_ids = [aws_security_group.app_b.id]

  tags = {
    Name = "ewb-app-b"
  }
}
