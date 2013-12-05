require 'sumo_control'

collector_id = '4216085'
source_id_log = '/var/spool/ec2/apache_sumo_source.txt'

sumo = SumoControl.new(user, password)
sumo.register(collector_id, source_id_log) do |source|
  source.category = 'apache'
  source.name = 'apache_tst_mc_1'
  source.remote_host = '123.2.2.2' # This machines IP
  source.remote_path = '/var/log/apache2/access_log'
  source.filters = SumoControl::COMMON_APACHE_FILTERS
end
