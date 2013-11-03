require 'json'

class SumoControl
  class SourceDefinition
    DEFAULTS = {
      :alive => true,
      :auth_method => 'key',
      :automatic_date_parsing => true,
      :category => '',
      :default_date_format => '',
      :description => '',
      :filters => [],
      :force_time_zone => false,
      :host_name => '',
      :key_password => '',
      :key_path => '/home/sumo/.ssh/id_rsa',
      :manual_prefix_regexp => '',
      :multiline_processing_enabled => false,
      :name => '',
      :remote_host => '',
      :remote_password => '',
      :remote_path => '',
      :remote_port => 22,
      :remote_user => 'root',
      :source_type => 'RemoteFile',
      :status => '',
      :time_zone => '',
      :user_autoline_matching => false
    }
    FIELDS = DEFAULTS.keys

    attr_accessor *FIELDS

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
      to_h.inspect
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
