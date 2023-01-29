variable "aws_region" {
  description = "AWS region"
  type        = string
  sensitive   = false
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "AWS EC2 tier"
  default = "t2.micro"
}

variable "ec2_ami" {
  description = "AWS AMI for EC2 instances"
  default = "ami-076309742d466ad69"
}

variable "ec2_user" {
  default = "ec2-user"
}

variable "key_pair_name" {
  description = "Key pair to use with EC2 instances"
  default = "default-key-pair"
}

variable "service_count" {
  default = 1
}

variable "env_tag" {
  description = "Tag which will be put to every resource in the provisioned environment"
  type = string
  default = "aws-terraform-demo"
}

variable "working_dir" {
}

variable "public_key_path" {
}

variable "private_key_path" {
}

variable "ansible_inventory_template_path" {
}

variable "ansible_inventory_rendered_path" {
}

variable "ansible_playbooks" {
  type = list
}

variable "metricbeat_template_path" {
}

variable "metricbeat_rendered_path" {
}

variable "kibana_template_path"{
}

variable "kibana_rendered_path" {
}

variable "elk_version" {
}
