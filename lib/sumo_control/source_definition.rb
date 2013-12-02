require 'json'

class SumoControl
  class SourceDefinition
    FIELDS = [
      :alive,
      :auth_method,
      :automatic_date_parsing,
      :category,
      :default_date_format,
      :description,
      :filters,
      :force_time_zone,
      :host_name,
      :key_password,
      :key_path,
      :manual_prefix_regexp,
      :multiline_processing_enabled,
      :name,
      :remote_host,
      :remote_password,
      :remote_path,
      :remote_port,
      :remote_user,
      :source_type,
      :status,
      :time_zone,
      :use_autoline_matching
    ]

    attr_accessor :id, :version, *FIELDS

    def self.from_payload(payload)
      source_payload = payload.fetch('source'){return nil}

      new(Hash[
        source_payload.map do |key, value|
          [
            key.split(/(?=[A-Z])/).map(&:downcase).join('_'),
            value
          ]
        end
      ])
    end

    def initialize(attributes = {})
      attributes.each do |key, value|
        writer = :"#{key}="
        send(writer, value) if respond_to?(writer)
      end
    end

    def to_json
      to_h.to_json
    end

    def to_s
      to_h.merge(
        :id => id,
        :version => version
      ).inspect
    end

    def to_h
      definition = Hash[
        FIELDS.map do |field|
          [lower_camelize(field), send(field)]
        end
      ]

      {'source' => definition}
    end

  private

    def lower_camelize(term)
      first, *others = term.to_s.split(/_/)
      others.map!(&:capitalize)
      [first, *others].join
    end
  end
end
