require 'rubygems'
require 'json'

require 'sumo_control/source_definition'
require 'sumo_control/source_entry'
require 'sumo_control/error'
require 'sumo_control/client'
require 'sumo_control/filters'

class SumoControl
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
    definition = client.create_source(collector_id, source_definition)
  rescue SumoControl::Error => error
    raise unless error.duplicate?

    definition = update_server_source(collector_id, source_definition)
  ensure
    store_source_id(definition, id_file_path)
  end

  def update_server_source(collector_id, source_definition)
    sources = client.sources(collector_id)
    source_id = sources.detect{|source| source == source_definition}.id

    remote_source_definition = client.source(collector_id, source_id)
    source_definition.id = remote_source_definition.id
    source_definition.version = remote_source_definition.version

    client.update_source(collector_id, source_definition)
  end


  def store_source_id(source_definition, id_file_path)
    File.open(id_file_path, "a") do |f|
      f.puts(source_definition.id)
    end
  end
end
