require 'sumo_control'

collector_id = '4216085'
source_id_log = '/var/spool/ec2/apache_sumo_source.txt'

sumo = SumoControl.new(user, password)
sumo.register(collector_id, source_id_log) do |source|
  # Tracking
  source.category = 'apache'
  source.name = 'apache_tst_mc_1'
  source.source_type = "RemoteFile"
  source.remote_path = '/var/log/apache2/access_log'
  source.filters = SumoControl::COMMON_APACHE_FILTERS

  # SSH Connection
  source.auth_method = 'key'
  source.remote_user = 'root'
  source.remote_password = nil
  source.remote_hosts = ['123.2.2.2'] # This machines IP
  source.remote_port = 22
  source.key_path = '/home/sumo/.ssh/id_rsa'
  source.key_password = nil
end
