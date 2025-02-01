provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}

resource "aws_subnet" "eks_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-1"
  }
}

resource "aws_subnet" "eks_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-2"
  }
}

resource "aws_security_group" "eks_sg" {
  name        = "eks-sg"
  description = "Allow Kubernetes access"
  vpc_id      = aws_vpc.eks_vpc.id
}

# Allow incoming traffic on port 443 (for Kubernetes API server)
resource "aws_security_group_rule" "eks_sg_ingress" {
  security_group_id = aws_security_group.eks_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow node-to-node communication
resource "aws_security_group_rule" "eks_sg_node_ingress" {
  security_group_id = aws_security_group.eks_sg.id
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
}
