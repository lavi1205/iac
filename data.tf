data "aws_ami" "eks_ami" {
  owners           = ["602401143452"]
  most_recent      = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.28-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}