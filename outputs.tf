output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_certificate_authority" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "launch_template_id" {
  value = aws_launch_template.eks_nodes.id
}

output "launch_template_latest_version" {
  value = aws_launch_template.eks_nodes.latest_version
}