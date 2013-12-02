require 'rubygems'
require 'json'

require File.expand_path('../sumo_control/source_definition', __FILE__)
require File.expand_path('../sumo_control/source_entry', __FILE__)
require File.expand_path('../sumo_control/error', __FILE__)
require File.expand_path('../sumo_control/client', __FILE__)
require File.expand_path('../sumo_control/filters', __FILE__)

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
