#####################################################################
# VPC
#####################################################################
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true
}

#####################################################################
# Public Subnet
#####################################################################
resource "aws_subnet" "this" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true
}

#####################################################################
# Internet Gateway
#####################################################################
resource "aws_internet_gateway" "this" {
  vpc_id     = aws_vpc.this.id
  depends_on = [aws_vpc.this]
}

# Route Table(s)
# Route the public subnet traffic through the IGW
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

# Route table and subnet associations
resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}

#####################################################################
# Security group for public subnet
#####################################################################
resource "aws_security_group" "this" {
  name   = "public-sg"
  vpc_id = aws_vpc.this.id
}

# Security group traffic rules
resource "aws_security_group_rule" "ingress_22" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_80" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ephemeral" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.this.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }
  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}

resource "aws_instance" "this" {
  depends_on = [
    aws_security_group.this,
    aws_iam_instance_profile.this
  ]
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = "t3.micro"
  key_name               = "eks_worker_test"
  vpc_security_group_ids = [aws_security_group.this.id]
  subnet_id              = aws_subnet.this.id
  user_data              = file("install_jenkins.sh")
  iam_instance_profile   = aws_iam_instance_profile.this.name

  associate_public_ip_address = true
  tags = {
    Name = "Jenkins-Instance"
  }
}

resource "aws_iam_role" "this" {
  name               = "Jenkins-iam-s3-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = "Jenkins"
  role = aws_iam_role.this.name
}