############################## Other paths ##############################

public_key = "keys/demo_ec2.pub"
working_dir = "/home/adam/UBB/master_pdae/1_felev/agile_devops/aws-terraform-demo"

private_key = "keys/pdae-ec2.pem"

ansible_inventory_template = "terraform_templates/ansible/inventory.ini.tftpl"
ansible_inventory_rendered = "terraform_generated/ansible/inventory.ini"

ansible_playbooks = [
  "ansible/elk/elasticsearch/install_elasticsearch.yaml",
  "ansible/elk/logstash/install_logstash.yaml",
  "ansible/elk/kibana/install_kibana.yaml",
  "ansible/services/install_nginx.yaml",
  "ansible/services/setup_metricbeat.yaml",
]

############################## ELK Stack ##############################

elk_version = "7.10.1"

metricbeat_template = "terraform_templates/elk/beats/metricbeat.yml.tftpl"
metricbeat_rendered = "terraform_generated/elk/beats/metricbeat.yml"

kibana_template = "terraform_templates/elk/kibana/kibana.yml.tftpl"
kibana_rendered = "terraform_generated/elk/kibana/kibana.yml"

logstash_pipelines_rendered = "terraform_generated/elk/logstash/pipelines/*.conf"
logstash_metricbeat_pipeline = "terraform_templates/elk/logstash/pipelines/metricbeat-pipeline.conf.tftpl"
logstash_metricbeat_pipeline_rendered = "terraform_generated/elk/logstash/pipelines/metricbeat-pipeline.conf"