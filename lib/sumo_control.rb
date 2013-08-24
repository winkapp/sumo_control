require 'rubygems'
require 'json'
require 'faraday'

module SumoControl

  def conn_sumo(host='https://api.sumologic.com', user=nil, password=nil)
    conn = Faraday.new(:url => host) do |r|
      r.response :logger
      r.adapter Faraday.default_adapter
    end

    conn.basic_auth(user, password)
    return conn
  end

  def apache_filters
    %([
      {
        "filterType": "Exclude",
        "name": "exclude health check",
        "regexp": ".*\\\\\\"GET /up HTTP/1\\\\.0\\\\\\".*"
      },
      {
        "filterType": "Exclude",
        "name": "exclude server-status",
        "regexp": ".*\\\\\\"GET /server-status\\\\?auto HTTP/1\\\\.1\\\\\\".*"
      }
    ])
  end

  def add_server_source(category='apache', source_name=nil, host_ip=nil, log_path=nil, id_file_path=nil, collector_id=nil, sumo_connection=nil)
    source_definition = %(
      {
        "source":
        {
          "alive": true,
          "authMethod": "key",
          "automaticDateParsing": true,
          "category": "#{category}",
          "defaultDateFormat": "",
          "description": "",
          "filters": #{send("#{category}_filters")},
          "forceTimeZone": false,
          "hostName": "",
          "keyPassword": "",
          "keyPath": "/home/sumo/.ssh/id_rsa",
          "manualPrefixRegexp": "",
          "multilineProcessingEnabled": false,
          "name": "#{source_name}",
          "remoteHost": "#{host_ip}",
          "remotePassword": "",
          "remotePath": "#{log_path}",
          "remotePort": 22,
          "remoteUser": "root",
          "sourceType": "RemoteFile",
          "status": "",
          "timeZone": "",
          "useAutolineMatching": false
        }
      }
    )

    print "json_msg="
    puts source_definition
    puts
    puts "ip=#{host_ip}"
    puts "server name=#{source_name}"

    response = sumo_connection.post do |req|
      req.url "/api/v1/collectors/#{collector_id}/sources"
      req.headers['Content-Type'] = 'application/json'
      req.body = source_definition
    end

    return response
  end

  def update_server_source(source_name=nil, host_ip=nil, collector_id=nil, sumo_connection=nil)
    sumo_api_path = "/api/v1/collectors/#{collector_id}/sources"
    search_response = sumo_connection.get sumo_api_path
    sources = JSON.parse(search_response.body)
    matched = sources['sources'].map do |source|
      source['name'] == source_name ? source : nil
    end.compact.first
    matched['remoteHost'] = host_ip
    matched['alive'] = true
    update_response = sumo_conection.put do |req|
      req.url = "#{sumo_api_path}/#{matched['id']}"
      req.body = {:source => matched}.to_json
      req.headers['Content-Type'] = 'application/json'
    end
    return update_response
  end

  def sumo_add_or_update(category='apache', source_name=nil, host_ip=nil, log_path=nil, id_file_path=nil, collector_id=nil, sumo_connection=nil)
    add_or_update_response = add_server_source(category, source_name, host_ip, log_path, id_file_path, collector_id, sumo_connection)
    if add_or_update_response.status == 400 && JSON.parse(add_or_update_response.body)['code'] == 'collectors.validation.name.duplicate'
      add_or_update_response = update_server_source(source_name, host_ip, collector_id, sumo_connection)
    end
    store_source_id(add_or_update_response) if add_or_update_response.status < 400
    return add_or_update_response
  end

  def store_source_id(response_object)
    json_response=response_object.body
    puts "Sumo Logic JSON response: #{json_response}"

    source_json=JSON.parse(json_response)
    source_id=source_json['source']['id']

    puts "Sumologic Source Id: #{source_id}"
    if !source_id
      puts "Invalid Sumologic Source ID returned. Exiting!"
      exit(1)
    else
      puts "Writing source id #{source_id} to #{id_file_path}"
      f = File.new(id_file_path,"a")
      f.puts(source_id)
      f.close
    end

  end

  def deactivate_sumo_source(id_file_path=nil, collector_id=nil, sumo_connection=nil)
    f = File.new(id_file_path, 'r')
    ids = f.readlines
    responses = ids.map do |id|
      source = sumo_connection.get "/api/v1/collectors/#{collector_id}/sources/#{id}"
      parsed = JSON.parse(source)
      parsed['source']['alive'] = false
      sumo_conection.put do |req|
        req.url = source_path
        req.body = parsed.to_json
        req.headers['Content-Type'] = 'application/json'
      end
    end
    return responses
  end

end
