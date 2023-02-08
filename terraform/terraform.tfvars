############################## Other paths ##############################
working_dir = "/home/adam/UBB/master_pdae/1_felev/agile_devops/aws-terraform-demo"
ip_list_file = "terraform_generated./"

public_key = "keys/demo_ec2.pub"

private_key = "keys/pdae-ec2.pem"

ansible_inventory_template = "terraform_templates/ansible/inventory.ini.tftpl"
ansible_inventory_rendered = "terraform_generated/ansible/inventory.ini"

ansible_playbooks = [
  "ansible/elk/elasticsearch/install_elasticsearch.yaml",
  "ansible/elk/logstash/install_logstash.yaml",
  "ansible/elk/kibana/install_kibana.yaml",
  "ansible/services/webserver.yaml",
  "ansible/services/scraper.yaml",
]

############################## ELK Stack ##############################

elk_version = "7.10.1"

kibana_template = "terraform_templates/elk/kibana/kibana.yml.tftpl"
kibana_rendered = "terraform_generated/elk/kibana/kibana.yml"

logstash_pipelines_rendered = "terraform_generated/elk/logstash/pipelines/*.conf"
logstash_beats_pipeline = "terraform_templates/elk/logstash/pipelines/beats-pipeline.conf.tftpl"
logstash_beats_pipeline_rendered = "terraform_generated/elk/logstash/pipelines/beats-pipeline.conf"

metricbeat_template = "terraform_templates/elk/beats/metricbeat.yml.tftpl"
metricbeat_rendered = "terraform_generated/elk/beats/metricbeat.yml"

filebeat_template = "terraform_templates/elk/beats/filebeat.yml.tftpl"
filebeat_rendered = "terraform_generated/elk/beats/filebeat.yml"