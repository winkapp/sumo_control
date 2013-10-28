require 'json'

module SumoControl
  class SourceDefinition
    def initialize(category, source_name, host_ip, log_path, filters)
      @category, @source_name, @host_ip, @log_path, @filters = category, source_name, host_ip, log_path, filters
    end

    def to_json
      {'source' => {
        "alive" => true,
        "authMethod" => "key",
        "automaticDateParsing" => true,
        "category" => @category,
        "defaultDateFormat" => "",
        "description" => "",
        "filters" => @filters,
        "forceTimeZone" => false,
        "hostName" => "",
        "keyPassword" => "",
        "keyPath" => "/home/sumo/.ssh/id_rsa",
        "manualPrefixRegexp" => "",
        "multilineProcessingEnabled" => false,
        "name" => @source_name,
        "remoteHost" => @host_ip,
        "remotePassword" => "",
        "remotePath" => @log_path,
        "remotePort" => 22,
        "remoteUser" => "root",
        "sourceType" => "RemoteFile",
        "status" => "",
        "timeZone" => "",
        "useAutolineMatching" => false
      }}.to_json
    end
    alias_method :to_json, :to_s
  end
end
