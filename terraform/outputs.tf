resource "local_file" "kibana_config" {
  content = templatefile(
    "${path.cwd}/${var.kibana_template}", 
    {
      elasticsearch_ip = aws_instance.elasticsearch.private_ip
    }
  )
  filename = "${path.cwd}/${var.kibana_rendered}"
}

resource "local_file" "logstash_beats_pipeline" {
  content = templatefile(
    "${path.cwd}/${var.logstash_beats_pipeline}", 
    {
      elasticsearch_ip = aws_instance.elasticsearch.private_ip,
    }
  )
  filename = "${path.cwd}/${var.logstash_beats_pipeline_rendered}"
}

resource "local_file" "metricbeat_config" {
  content = templatefile(
    "${path.cwd}/${var.metricbeat_template}", 
    {
      logstash_ip = aws_instance.logstash.private_ip,
      kibana_ip = aws_instance.kibana.private_ip
    }
  )
  filename = "${path.cwd}/${var.metricbeat_rendered}"
}

resource "local_file" "filebeat_config" {
  content = templatefile(
    "${path.cwd}/${var.filebeat_template}", 
    {
      logstash_ip = aws_instance.logstash.private_ip,
      kibana_ip = aws_instance.kibana.private_ip
    }
  )
  filename = "${path.cwd}/${var.filebeat_rendered}"
}

# public ips are used in the inventory (ansible must be able to connect to them)
resource "local_file" "ansible_inventory" {

  content = templatefile(
    "${path.cwd}/${var.ansible_inventory_template}", 
    {
      user = var.ec2_user,
      private_key = "${path.cwd}/${var.private_key}",

      service_ips = aws_instance.service[*].public_ip,
      scraper_ip = aws_instance.scraper.public_ip,

      logstash_ip = aws_instance.logstash.public_ip,
      elasticsearch_ip = aws_instance.elasticsearch.public_ip,
      kibana_ip = aws_instance.kibana.public_ip,
    
      elk_version = var.elk_version,
   
      kibana_config = "${path.cwd}/${var.kibana_rendered}"
      logstash_pipelines = "${path.cwd}/${var.logstash_pipelines_rendered}"

      metricbeat_config = "${path.cwd}/${var.metricbeat_rendered}",
      filebeat_config = "${path.cwd}/${var.filebeat_rendered}",
    }
  )
  filename = "${path.cwd}/${var.ansible_inventory_rendered}"
}

resource "null_resource" "run_ansible" { 
  provisioner "local-exec" {
    command = <<EOT
      export ANSIBLE_HOST_KEY_CHECKING=False &&
      %{for playbook in var.ansible_playbooks}
      ansible-playbook \
        -i "${path.cwd}/${var.ansible_inventory_rendered}" \
        "${path.cwd}/${playbook}"
      %{endfor}
    EOT
  }

  lifecycle {
    replace_triggered_by = [
      local_file.ansible_inventory,
      local_file.metricbeat_config,
      local_file.kibana_config
    ]
  }
}

resource "local_file" "public_ips" {

  # inventory contains all the ips
  depends_on = [
    local_file.ansible_inventory
  ]

  content = <<EOT
  services:
    %{for ip in aws_instance.service[*].public_ip}
    ${ip ~}
    %{endfor}
  kibana:
    ${aws_instance.kibana.public_ip}
  EOT
  filename = "${path.cwd}/${var.public_ip_file}"
}
