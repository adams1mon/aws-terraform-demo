terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "3.37.0"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    env = var.env-tag
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]
  tags = {
    env = var.env-tag
  }
}

resource "aws_route" "vpc_internet_access" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]
}


# TODO: maybe put the logging and monitoring stack in a separate subnet
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"

  # TODO: each instance in this subnet gets a public ip
  map_public_ip_on_launch = true
  
  depends_on = [
    aws_vpc.vpc
  ]
  tags = {
    env = var.env-tag
  }
}

resource "aws_security_group" "secgroup" {
  # name   = "secgroup"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_vpc.vpc
  ]

  tags = {
    env = var.env-tag
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)

  tags = {
    env = var.env-tag
  }
}

resource "aws_instance" "service_1" {
  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.secgroup.id]

  key_name = aws_key_pair.key_pair.id
  # connection {
  #   type        = "ssh"
  #   user        = "ec2-user"
  #   host        = self.public_ip
  #   private_key = file(var.private_key_path)
  # }

  # provisioner "local-exec" {
  #   command = "echo ${self.public_ip} > public_ip.txt"
  # }

  depends_on = [
    aws_subnet.subnet,
    aws_security_group.secgroup,
    aws_key_pair.key_pair
  ]

  tags = {
    env = var.env-tag
  }
}
