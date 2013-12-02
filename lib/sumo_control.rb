require 'rubygems'
require 'json'

require File.expand_path('../sumo_control/source_definition', __FILE__)
require File.expand_path('../sumo_control/source_entry', __FILE__)
require File.expand_path('../sumo_control/client', __FILE__)
require File.expand_path('../sumo_control/filters', __FILE__)

class SumoControl
  Error = Class.new(StandardError)

  def initialize(user, password)
    @client = Client.new(user, password)
  end

  def register(collector_id, id_file_path)
    yield (source_definition = SourceDefinition.new)

    register_source(collector_id, source_definition, id_file_path)
  end

private

  attr_reader :client

  def register_source(collector_id, source_definition, id_file_path)
    definition = add_server_source(collector_id, source_definition)
  rescue SumoControl::Error => error
    #raise unless error.duplicate?

    definition = update_server_source(collector_id, source_definition)
  ensure
    store_source_id(definition, id_file_path)
  end

  def add_server_source(collector_id, source_definition)
    print "json_msg="
    puts source_definition
    puts
    puts "ip=#{source_definition.remote_host}"
    puts "server name=#{source_definition.name}"

    client.create_source(collector_id, source_definition)
  end

  def update_server_source(collector_id, source_definition)
    search_response = client.sources(collector_id)

    sources = JSON.parse(search_response.body)
    matched = sources['sources'].map do |source|
      SourceEntry.new(source)
    end.detect{|source| source == source_definition}

    remove_source_definition = client.source(collector_id, matched.id)
    source_definition.id = remove_source_definition.id
    source_definition.version = remove_source_definition.version

    client.update_source(collector_id, source_definition)
  end


  def store_source_id(source_definition, id_file_path)
    File.open(id_file_path, "a") do |f|
      f.puts(source_definition.id)
    end
  end
end
