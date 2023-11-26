resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.name}-ec2-key-pair"
  public_key = tls_private_key.example.public_key_openssh
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "lb" {
  instance = aws_instance.ec2.id
  domain   = "vpc"
}

resource "aws_instance" "ec2" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = "t3.large"
  disable_api_termination = true
  key_name                = aws_key_pair.generated_key.key_name
  subnet_id               = aws_subnet.public[0].id
  vpc_security_group_ids  = [aws_security_group.ec2_sg.id] 
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    tags = merge(var.tags,{
        Name = "${var.name}-ec2-ebs"
    })    
  }

  tags = {
    Name = "${var.name}-ec2"    
  }
}

