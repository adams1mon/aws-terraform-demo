public_key_path = "../keys/demo_ec2.pub"
private_key_path = "../keys/pdae-ec2.pem"

ansible_inventory_template_path = "./templates/inventory.ini.tftpl"
ansible_inventory_rendered_path = "../ansible/inventory.ini"

ansible_playbooks = [
  "../ansible/nginx/install_nginx.yaml",
  "../ansible/elk/elasticsearch/install_elasticsearch.yaml",
]