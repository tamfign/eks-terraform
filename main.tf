provider "aws" {
  region = "ap-southeast-2"
}

# Define the VPC and Networking Resources
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
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-1"
  }
}

resource "aws_subnet" "eks_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-2b"
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

# Create an EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.eks_subnet_1.id,
      aws_subnet.eks_subnet_2.id,
    ]
    security_group_ids = [aws_security_group.eks_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_role_policy]
}

# IAM Role and Policies for EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_role_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_role_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Set Up Worker Nodes

# resource "aws_launch_configuration" "eks_launch_config" {
#   name          = "eks-launch-config"
#   image_id      = "ami-0a5395a56ccf8d85f"  # You can specify an EKS-optimized AMI
#   instance_type = "t2.micro"
#
#   security_groups = [aws_security_group.eks_sg.id]
#   user_data = <<-EOF
#               #!/bin/bash
#               /etc/eks/bootstrap.sh my-eks-cluster
#               EOF
# }
#
# resource "aws_autoscaling_group" "eks_asg" {
#   desired_capacity     = 2
#   max_size             = 3
#   min_size             = 2
#   launch_configuration = aws_launch_configuration.eks_launch_config.id
#   vpc_zone_identifier  = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]
#
#   tag {
#     key                 = "Name"
#     value               = "eks-worker"
#     propagate_at_launch = true
#   }
# }

resource "aws_launch_template" "eks_nodes" {
  name = "eks-node-template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  instance_type = "t2.micro"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.eks_nodes.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "EKS-managed-node"
    }
  }
}

resource "aws_security_group" "eks_nodes" {
  name        = "eks-node-group-sg"
  description = "Security group for EKS node group"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    description = "Allow node to node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-node-group-sg"
  }
}