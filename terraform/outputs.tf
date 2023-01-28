resource "local_file" "ansible_inventory" {
  content = templatefile(var.ansible_inventory_template_path, {
    public_ips = aws_instance.service[*].public_ip
    user = var.ec2_user,
    private_key_path = var.private_key_path
  })
  filename = var.ansible_inventory_rendered_path
}

resource "null_resource" "run_ansible" { 

  provisioner "local-exec" {
    command = <<EOT
      export ANSIBLE_HOST_KEY_CHECKING=False &&
      ansible-playbook -i ${var.ansible_inventory_rendered_path} ${var.ansible_playbook}
    EOT
  }
  
  depends_on = [
    local_file.ansible_inventory
  ]
}
