resource "local_file" "kibana_config" {
  content = templatefile(
    "${var.working_dir}/${var.kibana_template}", 
    {
      elasticsearch_ip = aws_instance.elasticsearch.private_ip
    }
  )
  filename = "${var.working_dir}/${var.kibana_rendered}"
}

resource "local_file" "logstash_beats_pipeline" {
  content = templatefile(
    "${var.working_dir}/${var.logstash_beats_pipeline}", 
    {
      elasticsearch_ip = aws_instance.elasticsearch.private_ip,
    }
  )
  filename = "${var.working_dir}/${var.logstash_beats_pipeline_rendered}"
}

resource "local_file" "metricbeat_config" {
  content = templatefile(
    "${var.working_dir}/${var.metricbeat_template}", 
    {
      logstash_ip = aws_instance.logstash.private_ip,
      kibana_ip = aws_instance.kibana.private_ip
    }
  )
  filename = "${var.working_dir}/${var.metricbeat_rendered}"
}

resource "local_file" "filebeat_config" {
  content = templatefile(
    "${var.working_dir}/${var.filebeat_template}", 
    {
      logstash_ip = aws_instance.logstash.private_ip,
      kibana_ip = aws_instance.kibana.private_ip
    }
  )
  filename = "${var.working_dir}/${var.filebeat_rendered}"
}

# public ips are used in the inventory (ansible must be able to connect to them)
resource "local_file" "ansible_inventory" {

  content = templatefile(
    "${var.working_dir}/${var.ansible_inventory_template}", 
    {
      user = var.ec2_user,
      private_key = "${var.working_dir}/${var.private_key}",

      service_ips = aws_instance.service[*].public_ip,
      scraper_ip = aws_instance.scraper.public_ip,

      logstash_ip = aws_instance.logstash.public_ip,
      elasticsearch_ip = aws_instance.elasticsearch.public_ip,
      kibana_ip = aws_instance.kibana.public_ip,
    
      elk_version = var.elk_version,
   
      kibana_config = "${var.working_dir}/${var.kibana_rendered}"
      logstash_pipelines = "${var.working_dir}/${var.logstash_pipelines_rendered}"

      metricbeat_config = "${var.working_dir}/${var.metricbeat_rendered}",
      filebeat_config = "${var.working_dir}/${var.filebeat_rendered}",
    }
  )
  filename = "${var.working_dir}/${var.ansible_inventory_rendered}"
}

resource "null_resource" "run_ansible" { 
  provisioner "local-exec" {
    command = <<EOT
      export ANSIBLE_HOST_KEY_CHECKING=False &&
      %{for playbook in var.ansible_playbooks}
      ansible-playbook \
        -i "${var.working_dir}/${var.ansible_inventory_rendered}" \
        "${var.working_dir}/${playbook}"
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
