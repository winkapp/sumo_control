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

    updated_source_definition = register_source(collector_id, source_definition)
    store_source_id(updated_source_definition, id_file_path)

    updated_source_definition
  end

private

  attr_reader :client

  def register_source(collector_id, source_definition)
    client.create_source(collector_id, source_definition)
  rescue SumoControl::Error => error
    raise unless error.duplicate?

    source_definition.identify_as(remote_source_definition(collector_id, source_definition))
    client.update_source(collector_id, source_definition)
  end

  def remote_source_definition(collector_id, source_definition)
    source_id = lookup_source_id(collector_id, source_definition)

    client.source(collector_id, source_id)
  end

  def lookup_source_id(collector_id, source_definition)
    client.sources(collector_id).detect{|source| source == source_definition}.id
  end


  def store_source_id(source_definition, id_file_path)
    File.open(id_file_path, "a") do |f|
      f.puts(source_definition.id)
    end
  end
end
