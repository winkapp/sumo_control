class SumoControl
  class SourceEntry
    attr_accessor :id, :name

    def initialize(attributes)
      attributes.each do |key, value|
        writer = :"#{key}="
        send(writer, value) if respond_to?(writer)
      end
    end

    def ==(other)
      name == other.name
    end
  end
end
