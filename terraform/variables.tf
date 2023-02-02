##############################  AWS  ##############################

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

############################## Other paths ##############################

variable "working_dir" {
}

variable "public_key" {
}

variable "private_key" {
}

variable "ansible_inventory_template" {
}

variable "ansible_inventory_rendered" {
}

variable "ansible_playbooks" {
  type = list
}

############################## ELK Stack ##############################

variable "elk_version" {
}

variable "metricbeat_template" {
}

variable "metricbeat_rendered" {
}

variable "kibana_template"{
}

variable "kibana_rendered" {
}

variable "logstash_pipelines_rendered" {
}

variable "logstash_metricbeat_pipeline" {
}

variable "logstash_metricbeat_pipeline_rendered" {
}
