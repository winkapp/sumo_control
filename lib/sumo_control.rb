require 'rubygems'
require 'json'
require 'faraday'
require File.expand_path('../sumo_control/source_definition', __FILE__)
require File.expand_path('../sumo_control/client', __FILE__)

module SumoControl

  def conn_sumo(user, password)
    @client = Client.new(user, password)
  end

  def sumo_add_or_update(category, source_name, host_ip, log_path, id_file_path, collector_id)
    add_or_update_response = add_server_source(category, source_name, host_ip, log_path, collector_id)
    if add_or_update_response.status == 400 && JSON.parse(add_or_update_response.body)['code'] == 'collectors.validation.name.duplicate'
      add_or_update_response = update_server_source(source_name, host_ip, collector_id)
    end
    store_source_id(add_or_update_response, id_file_path) if add_or_update_response.status < 400
    return add_or_update_response
  end

private

  attr_reader :client

  def apache_filters
    [
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

  def add_server_source(category, source_name, host_ip, log_path, collector_id)
    source_definition = SourceDefinition.new(category, source_name, host_ip, log_path, send("#{category}_filters"))

    print "json_msg="
    puts source_definition
    puts
    puts "ip=#{host_ip}"
    puts "server name=#{source_name}"

    client.create_source(collector_id, source_definition)
  end

  def update_server_source(source_name, host_ip, collector_id)
    search_response = client.sources(collector_id)

    sources = JSON.parse(search_response.body)
    matched = sources['sources'].detect{|source| source['name'] == source_name}

    source_response = client.source(collector_id, matched['id'])
    matched['remoteHost'] = host_ip

    client.update_source(collector_id, matched['id'], matched, source_response.headers['etag'])
  end


  def store_source_id(response_object, id_file_path)
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
      File.open(id_file_path, "a") do |f|
        f.puts(source_id)
      end
    end

  end
end
