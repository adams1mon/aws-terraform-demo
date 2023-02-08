
resource "aws_subnet" "monitoring_subnet" {
  vpc_id                  = var.vpc.id
  cidr_block              = var.subnet_cidr

  # each instance in this subnet gets a public ip
  map_public_ip_on_launch = true
  
  depends_on = [
    aws_vpc.vpc
  ]
  tags = {
    env = var.env_tag
  }
}

resource "aws_security_group" "monitoring_vpc_internal_secgroup" {
  name   = "monitoring_vpc_internal_secgroup"
  vpc_id = var.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # TODO: this might be a security issue
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    env = var.env_tag
  }
}

resource "aws_security_group" "kibana_secgroup" {
  name   = "kibana_secgroup"
  vpc_id = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    env = var.env_tag
  }
}

resource "aws_instance" "logstash" {
  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.monitoring_subnet.id

  vpc_security_group_ids = [
    aws_security_group.service_vpc_internal_secgroup.id, 
  ]

  key_name = var.key_pair_id

  depends_on = [
    aws_subnet.monitoring_subnet,
    aws_security_group.service_vpc_internal_secgroup,
  ]

  tags = {
    env = var.env_tag
    role = "elk_logging_monitoring",
    name = "logstash"
  }

  # wait until the resource is "reachable" by connecting to it
  provisioner "remote-exec" {
    connection {
      host = self.public_ip
      user = var.ec2_user
      type = "ssh"
      private_key = file(var.private_key_file)
    }

    inline = ["echo terraform connected!"]
  }
}

resource "aws_instance" "elasticsearch" {
  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.monitoring_subnet.id
  
  vpc_security_group_ids = [
    aws_security_group.service_vpc_internal_secgroup.id
  ]

  key_name = var.key_pair_id

  depends_on = [
    aws_subnet.monitoring_subnet,
    aws_security_group.service_vpc_internal_secgroup,
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
      private_key = file(var.private_key_file)
    }

    inline = ["echo terraform connected!"]
  }
}

resource "aws_instance" "kibana" {
  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.monitoring_subnet.id

  vpc_security_group_ids = [
    aws_security_group.http_service_secgroup.id, 
    aws_security_group.kibana_secgroup.id, 
    aws_security_group.service_vpc_internal_secgroup.id, 
  ]

  key_name = var.key_pair_id

  depends_on = [
    aws_subnet.monitoring_subnet,
    aws_security_group.http_service_secgroup, 
    aws_security_group.kibana_secgroup, 
    aws_security_group.service_vpc_internal_secgroup,
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
      private_key = file(var.private_key_file)
    }

    inline = ["echo terraform connected!"]
  }
}