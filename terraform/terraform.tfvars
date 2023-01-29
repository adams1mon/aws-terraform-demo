public_key_path = "keys/demo_ec2.pub"
working_dir = "/home/adam/UBB/master_pdae/1_felev/agile_devops/aws-terraform-demo"

private_key_path = "keys/pdae-ec2.pem"

ansible_inventory_template_path = "terraform_templates/ansible/inventory.ini.tftpl"
ansible_inventory_rendered_path = "terraform_generated/ansible/inventory.ini"

ansible_playbooks = [
  "ansible/elk/elasticsearch/install_elasticsearch.yaml",
  "ansible/elk/kibana/install_kibana.yaml",
  "ansible/services/install_nginx.yaml",
  "ansible/services/setup_metricbeat.yaml",
]

metricbeat_template_path = "terraform_templates/elk/beats/metricbeat.yml.tftpl"
metricbeat_rendered_path = "terraform_generated/elk/beats/metricbeat.yml"

kibana_template_path = "terraform_templates/elk/kibana/kibana.yml.tftpl"
kibana_rendered_path = "terraform_generated/elk/kibana/kibana.yml"

elk_version = "7.10.1"