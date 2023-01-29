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
    env = var.env_tag
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]
  tags = {
    env = var.env_tag
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
    env = var.env_tag
  }
}

resource "aws_security_group" "service_secgroup" {
  name   = "service_secgroup"
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
    env = var.env_tag
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)

  tags = {
    env = var.env_tag
  }
}

resource "aws_instance" "service" {
  count = var.service_count

  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.service_secgroup.id]

  key_name = aws_key_pair.key_pair.id

  depends_on = [
    aws_subnet.subnet,
    aws_security_group.service_secgroup,
    aws_key_pair.key_pair
  ]

  tags = {
    env = var.env_tag
    role = "service",
    name = "service_${count.index}"
  }

  # wait until the resource is "reachable" by connecting to it
  provisioner "remote-exec" {
    connection {
      host = aws_instance.service[count.index].public_ip
      user = var.ec2_user
      type = "ssh"
      private_key = file(var.private_key_path)
    }

    inline = ["echo terraform connected!"]
  }
}


resource "aws_security_group" "monitoring_secgroup" {
  name   = "monitoring_secgroup"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # all traffic from inside the vpc
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
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
    env = var.env_tag
  }
}

resource "aws_instance" "elasticsearch" {
  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.monitoring_secgroup.id]

  key_name = aws_key_pair.key_pair.id

  depends_on = [
    aws_subnet.subnet,
    aws_security_group.monitoring_secgroup,
    aws_key_pair.key_pair
  ]

  tags = {
    env = var.env_tag
    role = "elk_logging_monitoring",
    name = "elasticsearch"
  }

  # wait until the resource is "reachable" by connecting to it
  provisioner "remote-exec" {
    connection {
      host = self.public_ip
      user = var.ec2_user
      type = "ssh"
      private_key = file(var.private_key_path)
    }

    inline = ["echo terraform connected!"]
  }
}

resource "aws_instance" "kibana" {
  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.monitoring_secgroup.id]

  key_name = aws_key_pair.key_pair.id

  depends_on = [
    aws_subnet.subnet,
    aws_security_group.monitoring_secgroup,
    aws_key_pair.key_pair
  ]

  tags = {
    env = var.env_tag
    role = "elk_logging_monitoring",
    name = "kibana"
  }

  # wait until the resource is "reachable" by connecting to it
  provisioner "remote-exec" {
    connection {
      host = self.public_ip
      user = var.ec2_user
      type = "ssh"
      private_key = file(var.private_key_path)
    }

    inline = ["echo terraform connected!"]
  }
}