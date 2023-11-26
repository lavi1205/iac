locals {
  value = {
    cluster_name = aws_eks_cluster.eks_cluster.name
    irsa_alb     = aws_iam_role.eks_cluster_irsa_aws-load-balancer-controller.arn
  }
}

resource "aws_ssm_parameter" "terraform_ouput" {
  name  = "terraform_ouput"
  type  = "StringList"
  value = jsonencode(local.value)
  tags  = merge(var.tags,{
    Name = "terraform-output"
  })
  depends_on = [ aws_eks_cluster.eks_cluster ]
}