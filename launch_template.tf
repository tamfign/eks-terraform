resource "aws_launch_template" "eks_nodes" {
  name = "${var.cluster_name}-node-template"

  # Specify instance requirements
  instance_type = "t2.micro"

  # Enable metadata v2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # Enable detailed monitoring
  monitoring {
    enabled = true
  }

  # # Block device mappings for additional storage
  # block_device_mappings {
  #   device_name = "/dev/xvda"
  #
  #   ebs {
  #     volume_size           = 20
  #     volume_type          = "gp3"
  #     delete_on_termination = true
  #     encrypted            = true
  #   }
  # }

  # Network configuration
  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.node_group.id]
  }

  # User data for node bootstrapping
  user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==BOUNDARY=="

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${var.cluster_name} \
  --b64-cluster-ca ${aws_eks_cluster.main.certificate_authority[0].data} \
  --apiserver-endpoint ${aws_eks_cluster.main.endpoint} \
  --dns-cluster-ip 172.20.0.10 \
  --container-runtime containerd \
  --kubelet-extra-args '--max-pods=110'

--==BOUNDARY==--
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-node"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.cluster_name}-node-volume"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}