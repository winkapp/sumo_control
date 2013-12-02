class SumoControl
  class Error < StandardError
    attr_reader :id, :code, :status

    def initialize(payload)
      @id, message, @code, @status = payload.values_at('id', 'message', 'code', 'status')

      super(message)
    end

    def duplicate?
      code == 'collectors.validation.name.duplicate'
    end
  end
end
