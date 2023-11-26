resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags,{
    Resource_type = "vpc"
    Name          = "${var.name}-vpc"
  })
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  count      = length(var.public_subnet)
  cidr_block = var.public_subnet[count.index]
  tags       = merge(var.tags,{
    Name     = "${var.name}-public",
    Resource_type = "subnet"
  })
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  count      = length(var.private_subnet)
  cidr_block = var.private_subnet[count.index]
  availability_zone = element(var.availability_zone, count.index)
  tags       = merge(var.tags,{
    Name     = "${var.name}-private-${count.index}",
    Resource_type = "subnet"
  })
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.name}-ec2"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge(var.tags,{
    Name = "${var.name}-ec2-sg",
    Resource_type = "security group"
  })
}

resource "aws_eip" "nat_eip" {
  domain   = "vpc"
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags,{
    Name = "${var.name}-igw"
  })
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id         = element(aws_subnet.public[*].id,0)
  
  depends_on = [ aws_internet_gateway.igw ]
  tags = merge(var.tags,{
    Name = "${var.name}-natgw"
  })
}


resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name}-publicRT",
    Resource_type = "Route Table"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
    }

  tags = {
    Name = "${var.name}-privateRT",
    Resource_type = "Route Table"
  }
}

resource "aws_route_table_association" "public_route" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = element(aws_route_table.public_route[*].id, count.index)
}

resource "aws_route_table_association" "private_route" {
  count          = length(aws_subnet.private)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private_route.id
}