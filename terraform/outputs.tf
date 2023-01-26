data "template_file" "ansible_inventory" {
  template = file("./templates/inventory.ini.tpl")
  count = length(aws_instance.service_1[*].public_ip)
  vars = {
    public_ip = element(aws_instance.service_1[*].public_ip, count.index)
    user = "ec2-user"
    private_key_path = var.private_key_path
  }
}

# generate the Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = data.template_file.ansible_inventory.rendered
  filename = "../ansible/inventory.ini"
}
