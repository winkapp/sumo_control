class SumoControl
  COMMON_APACHE_FILTERS = [
    {
      :filterType => "Exclude",
      :name => "exclude health check",
      :regexp => /.*\"GET \/up HTTP\/1\.0\".*/.inspect[1...-1]
    },
    {
      :filterType => "Exclude",
      :name => "exclude server-status",
      :regexp => /.*\"GET \/server-status\?auto HTTP\/1\.1\".*/.inspect[1...-1]
    }
  ]
end
