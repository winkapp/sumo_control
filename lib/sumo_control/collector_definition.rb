require 'json'

class SumoControl
  class CollectorDefinition
    FIELDS = [
      :alive,
      :category,
      :collector_type,
      :collector_version,
      :cutoff_relative_time,
      :cutoff_timestamp,
      :description,
      :ephemeral,
      :host_name,
      :id,
      :last_seen_alive,
      :links,
      :name,
      :os_arch,
      :os_name,
      :os_time,
      :os_version,
      :source_sync_mode,
      :target_cpu,
      :time_zone,
    ]

    attr_accessor :version, *FIELDS

    def self.from_payload(collector_payload, version = nil)
      assignment_method = lambda{|key| key.split(/(?=[A-Z])/).map(&:downcase).join('_') + '='}

      collector_definition = collector_payload.inject(new) do |definition, (key, value)|
        definition.send(assignment_method[key], value)
        definition
      end

      collector_definition.version = version

      collector_definition
    end

    def initialize(attributes = {})
      attributes.each do |key, value|
        writer = :"#{key}="
        send(writer, value) if respond_to?(writer)
      end
    end

    def identify_as(other_definition)
      self.id = other_definition.id
      self.version = other_definition.version
    end

    def ==(other)
      name == other.name
    end

    def to_json
      to_h.to_json
    end

    def to_s
      JSON.pretty_generate(to_h.merge(:version => version))
    end

    def to_h
      definition = Hash[
        FIELDS.map do |field|
          [lower_camelize(field), send(field)]
        end
      ]

      {:collector => definition}
    end

  private

    def lower_camelize(term)
      first, *others = term.to_s.split(/_/)
      others.map!(&:capitalize)
      [first, *others].join
    end
  end
end
