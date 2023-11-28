resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.name}-eks-thinh123-2000"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids = [element(aws_subnet.private[*].id, 0), element(aws_subnet.private[*].id, 1)]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [aws_iam_role.eks_cluster]

  tags = merge(var.tags,{
    Name = "${var.name}-eks-thinh123-2000"
  })
}

resource "tls_private_key" "eks_cluster" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "eks_cluster" {
  key_name   = "${var.name}-ng-key-pair"
  public_key = tls_private_key.eks_cluster.public_key_openssh
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.name}-eks-sg"
  description = "Manager node group traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags,{
    Name = "${var.name}-eks-sg"
  })
}

resource "aws_security_group" "managed_ng_sg" {
    name        = "${var.name}-eks-sg-ng"
  description = "Manager node group traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags,{
    Name = "${var.name}-eks-sg-ng"
  })
}
resource "aws_launch_template" "eks_cluster" {
    name          = "${var.name}-eks-lt"
    image_id      = data.aws_ami.eks_ami.id
    instance_type = var.eks_ng_instance
    key_name      =  aws_key_pair.eks_cluster.key_name
    block_device_mappings {
        device_name = "/dev/sdf"

        ebs {
        volume_size = 20
        }
  }

    metadata_options {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
        instance_metadata_tags      = "enabled"
  }
  user_data = base64encode(templatefile("user_data.tpl", {cluster_name=aws_eks_cluster.eks_cluster.name,certificate-authority=aws_eks_cluster.eks_cluster.certificate_authority[0].data,api-server-endpoint=aws_eks_cluster.eks_cluster.endpoint}))

  vpc_security_group_ids = [aws_security_group.managed_ng_sg.id]

  tags = merge(var.tags,{
    Name = "${var.name}-eks-lt"
  })
}


resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name ="${var.name}-eks-ng-lt"
  node_role_arn   = aws_iam_role.eks-ng.arn
  subnet_ids      = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.eks_cluster.id
    version = 1
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  taint {
    key = var.taint_key
    value = var.taint_value
    effect = "NO_SCHEDULE"
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role.eks-ng
  ]

  lifecycle {
    ignore_changes = [launch_template[1].version]
  }

  tags = merge(var.tags,{
    Name = "${var.name}-eks-ng-lt"
  })
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"
  addon_version = "v1.14.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.eks_cluster_irsa_cni.arn
  depends_on = [ aws_iam_role.eks_cluster_irsa_cni]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
  addon_version = "v1.10.1-eksbuild.2"
  depends_on = [aws_eks_node_group.example]
  configuration_values = jsonencode({
      tolerations : [{
        key = "${var.taint_key}"
        value = "${var.taint_value}"
        operator = "Equal"
        effect   = "NoSchedule"
    },]
  })
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
  addon_version = "v1.28.1-eksbuild.1"
}

resource "aws_eks_addon" "ebs-csi-driver" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
  addon_version = "v1.25.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.eks_cluster_irsa_ebs_csi_driver.arn
  configuration_values = jsonencode({
  "controller": {
    tolerations : [
      {
        key = "${var.taint_key}"
        value = "${var.taint_value}"
        operator = "Equal"
        effect   = "NoSchedule"
      },
    ]
  }
})
  depends_on = [ aws_iam_role.eks_cluster_irsa_ebs_csi_driver, aws_eks_node_group.example ]
}

resource "null_resource" "provision" {

  provisioner "local-exec" {
    command = "../script/k8s-alb.sh"
    interpreter=["/bin/bash", "-c"]

    environment = {
      IRSA_ALB = "${aws_iam_role.eks_cluster_irsa_aws-load-balancer-controller.arn}"
      TAINT_KEY   = "${var.taint_key}"
      TAINT_VALUE = "${var.taint_value}" 
    }
  }
  depends_on = [aws_eks_cluster.eks_cluster,aws_eks_node_group.example ]
}