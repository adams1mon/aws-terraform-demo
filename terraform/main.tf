terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  public_key_path_adjusted = "${path.root}/${var.public_key}"
  private_key_path_adjusted = "${path.root}/${var.private_key}"
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


resource "aws_subnet" "service_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"

  # each instance in this subnet gets a public ip
  map_public_ip_on_launch = true
  
  depends_on = [
    aws_vpc.vpc
  ]
  tags = {
    env = var.env_tag
  }
}


# resource "aws_subnet" "monitoring_subnet" {
#   vpc_id                  = aws_vpc.vpc.id
#   cidr_block              = "10.0.1.0/24"

#   # each instance in this subnet gets a public ip
#   map_public_ip_on_launch = true
  
#   depends_on = [
#     aws_vpc.vpc
#   ]
#   tags = {
#     env = var.env_tag
#   }
# }

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_pair_name
  public_key = file(local.public_key_path_adjusted)

  tags = {
    env = var.env_tag
  }
}

resource "aws_security_group" "service_vpc_internal_secgroup" {
  name   = "service_vpc_internal_secgroup"
  vpc_id = aws_vpc.vpc.id

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
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  # TODO: this might be a security issue
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


# resource "aws_security_group" "http_service_secgroup" {
#   name   = "http_service_secgroup"
#   vpc_id = aws_vpc.vpc.id
  
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   depends_on = [
#     aws_vpc.vpc
#   ]

#   tags = {
#     env = var.env_tag
#   }
# }

# also has the 5601 port exposed
# resource "aws_security_group" "kibana_secgroup" {
#   name   = "kibana_secgroup"
#   vpc_id = aws_vpc.vpc.id
  
#   ingress {
#     from_port   = 80
#     to_port     = 5601
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  
#   depends_on = [
#     aws_vpc.vpc
#   ]

#   tags = {
#     env = var.env_tag
#   }
# }

resource "aws_instance" "service" {
  # arbitrary service counts, just to explore this functionality too
  count = var.service_count

  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.service_subnet.id

  vpc_security_group_ids = [
    aws_security_group.service_vpc_internal_secgroup.id, 
    aws_security_group.http_service_secgroup.id
  ]

  key_name = aws_key_pair.key_pair.id

  depends_on = [
    aws_subnet.service_subnet,
    aws_security_group.service_vpc_internal_secgroup,
    aws_security_group.http_service_secgroup,
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
      private_key = file(local.private_key_path_adjusted)
    }

    inline = ["echo terraform connected!"]
  }
}


resource "aws_instance" "scraper" {

  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.service_subnet.id

  vpc_security_group_ids = [
    aws_security_group.service_vpc_internal_secgroup.id, 
  ]

  key_name = aws_key_pair.key_pair.id

  depends_on = [
    aws_subnet.service_subnet,
    aws_security_group.service_vpc_internal_secgroup,
    aws_key_pair.key_pair
  ]

  tags = {
    env = var.env_tag
    role = "service",
    name = "scraper"
  }

  # wait until the resource is "reachable" by connecting to it
  provisioner "remote-exec" {
    connection {
      host = aws_instance.scraper.public_ip
      user = var.ec2_user
      type = "ssh"
      private_key = file(local.private_key_path_adjusted)
    }

    inline = ["echo terraform connected!"]
  }
}

# resource "aws_instance" "logstash" {
#   ami                    = var.ec2_ami
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.monitoring_subnet.id

#   vpc_security_group_ids = [
#     aws_security_group.vpc_internal_secgroup.id, 
#   ]

#   key_name = aws_key_pair.key_pair.id

#   depends_on = [
#     aws_subnet.monitoring_subnet,
#     aws_security_group.vpc_internal_secgroup,
#     aws_key_pair.key_pair
#   ]

#   tags = {
#     env = var.env_tag
#     role = "elk_logging_monitoring",
#     name = "logstash"
#   }

#   # wait until the resource is "reachable" by connecting to it
#   provisioner "remote-exec" {
#     connection {
#       host = self.public_ip
#       user = var.ec2_user
#       type = "ssh"
#       private_key = file(local.private_key_path_adjusted)
#     }

#     inline = ["echo terraform connected!"]
#   }
# }

# resource "aws_instance" "elasticsearch" {
#   ami                    = var.ec2_ami
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.monitoring_subnet.id
  
#   vpc_security_group_ids = [
#     aws_security_group.vpc_internal_secgroup.id
#   ]

#   key_name = aws_key_pair.key_pair.id

#   depends_on = [
#     aws_subnet.monitoring_subnet,
#     aws_security_group.vpc_internal_secgroup,
#     aws_key_pair.key_pair
#   ]

#   tags = {
#     env = var.env_tag
#     role = "elk_logging_monitoring",
#     name = "elasticsearch"
#   }

#   # wait until the resource is "reachable" by connecting to it
#   provisioner "remote-exec" {
#     connection {
#       host = self.public_ip
#       user = var.ec2_user
#       type = "ssh"
#       private_key = file(local.private_key_path_adjusted)
#     }

#     inline = ["echo terraform connected!"]
#   }
# }

# resource "aws_instance" "kibana" {
#   ami                    = var.ec2_ami
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.monitoring_subnet.id

#   vpc_security_group_ids = [
#     aws_security_group.http_service_secgroup.id, 
#     aws_security_group.kibana_secgroup.id, 
#     aws_security_group.vpc_internal_secgroup.id, 
#   ]

#   key_name = aws_key_pair.key_pair.id

#   depends_on = [
#     aws_subnet.monitoring_subnet,
#     aws_security_group.http_service_secgroup, 
#     aws_security_group.kibana_secgroup, 
#     aws_security_group.vpc_internal_secgroup,
#     aws_key_pair.key_pair
#   ]

#   tags = {
#     env = var.env_tag
#     role = "elk_logging_monitoring",
#     name = "kibana"
#   }

#   # wait until the resource is "reachable" by connecting to it
#   provisioner "remote-exec" {
#     connection {
#       host = self.public_ip
#       user = var.ec2_user
#       type = "ssh"
#       private_key = file(local.private_key_path_adjusted)
#     }

#     inline = ["echo terraform connected!"]
#   }
# }