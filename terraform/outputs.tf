resource "local_file" "ansible_inventory" {

  content = templatefile(var.ansible_inventory_template_path, {
    service_ips = aws_instance.service[*].public_ip,
    elasticsearch_ip = aws_instance.elasticsearch.public_ip,
    elk_version = var.elk_version,
    user = var.ec2_user,
    private_key_path = var.private_key_path
  })

  filename = var.ansible_inventory_rendered_path
}

resource "local_file" "metricbeat_config" {

  content = templatefile(var.metricbeat_template_path, {
    elasticsearch_ip = aws_instance.elasticsearch.public_ip
  })

  filename = var.metricbeat_rendered_path
}

resource "null_resource" "run_ansible" { 
  provisioner "local-exec" {
    command = <<EOT
      export ANSIBLE_HOST_KEY_CHECKING=False &&
      %{for playbook in var.ansible_playbooks}
      ansible-playbook -i ${var.ansible_inventory_rendered_path} ${playbook} \
      %{endfor}
    EOT
  }
  
  depends_on = [
    local_file.ansible_inventory
  ]
}
