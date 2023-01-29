# TODO: use private ips here

resource "local_file" "metricbeat_config" {
  content = templatefile(
    "${var.working_dir}/${var.metricbeat_template_path}", 
    {
      elasticsearch_ip = aws_instance.elasticsearch.public_ip,
      kibana_ip = aws_instance.kibana.public_ip
    }
  )
  filename = "${var.working_dir}/${var.metricbeat_rendered_path}"
}

resource "local_file" "kibana_config" {
  content = templatefile(
    "${var.working_dir}/${var.kibana_template_path}", 
    {
      elasticsearch_ip = aws_instance.elasticsearch.public_ip
    }
  )
  filename = "${var.working_dir}/${var.kibana_rendered_path}"
}

# public ips are used in the inventory (ansible must be able to connect to them)
resource "local_file" "ansible_inventory" {

  content = templatefile(
    "${var.working_dir}/${var.ansible_inventory_template_path}", 
    {
      user = var.ec2_user,
      private_key_path = "${var.working_dir}/${var.private_key_path}",

      service_ips = aws_instance.service[*].public_ip,
      elasticsearch_ip = aws_instance.elasticsearch.public_ip,
      kibana_ip = aws_instance.kibana.public_ip,
    
      elk_version = var.elk_version,
   
      metricbeat_config = "${var.working_dir}/${var.metricbeat_rendered_path}",
      kibana_config = "${var.working_dir}/${var.kibana_rendered_path}"
    }
  )
  filename = "${var.working_dir}/${var.ansible_inventory_rendered_path}"
}

resource "null_resource" "run_ansible" { 
  provisioner "local-exec" {
    command = <<EOT
      export ANSIBLE_HOST_KEY_CHECKING=False &&
      %{for playbook in var.ansible_playbooks}
      ansible-playbook -i "${var.working_dir}/${var.ansible_inventory_rendered_path}" "${var.working_dir}/${playbook}" \
      %{endfor}
    EOT
  }
  
  depends_on = [
    local_file.ansible_inventory,
    local_file.metricbeat_config,
    local_file.kibana_config
  ]
}
