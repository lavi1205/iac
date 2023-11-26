output "subnet_id" {
    value = aws_subnet.private[*].id
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "irsa_alb" {
  value = aws_iam_role.eks_cluster_irsa_aws-load-balancer-controller.arn
}

