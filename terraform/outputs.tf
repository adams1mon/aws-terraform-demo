resource "local_file" "ansible_inventory" {
  content = templatefile(var.ansible_inventory_template_path, {
    service_ips = aws_instance.service[*].public_ip,
    elasticsearch_ips = aws_instance.elasticsearch[*].public_ip
    user = var.ec2_user,
    private_key_path = var.private_key_path
  })
  filename = var.ansible_inventory_rendered_path
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
