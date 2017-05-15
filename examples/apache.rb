require 'sumo_control'

collector_id = '4216085'
source_definition = SumoControl::SourceDefinition.new(
  category: 'apache',
  name: 'apache_tst_mc_1',
  source_type: 'RemoteFile',
  remote_path: '/var/log/apache2/access_log',
  filters: SumoControl::COMMON_APACHE_FILTERS,
  auth_method: 'key',
  remote_user: 'root',
  remote_password: nil,
  remote_hosts: ['123.2.2.2'],  # This machines IP
  remote_port: 22,
  key_path: '/home/sumo/.ssh/id_rsa',
  key_password: nil
)
source_id_log = '/var/spool/ec2/apache_sumo_source.txt'

sumo = SumoControl.new(user, password)
updated_source_definition = sumo.register_file_source(collector_id, source_definition, source_id_log)
