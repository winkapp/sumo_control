require 'faraday'

class SumoControl
  class Client
    API_HOST = 'https://api.sumologic.com'

    attr_reader :connection

    def initialize(user, password)
      @connection = Faraday.new(:url => API_HOST) do |r|
        r.response :logger
        r.adapter Faraday.default_adapter
      end
      @connection.basic_auth(user, password)
    end

    def sources(collector_id)
      connection.get "/api/v1/collectors/#{collector_id}/sources"
    end

    def source(collector_id, source_id)
      response = connection.get "/api/v1/collectors/#{collector_id}/sources/#{source_id}"

      handle_response(response) do |payload|
        SourceDefinition.from_payload(payload, response.headers['etag'])
      end
    end

    def create_source(collector_id, source_definition)
      response = connection.post do |req|
        req.url "/api/v1/collectors/#{collector_id}/sources"
        req.headers['Content-Type'] = 'application/json'
        req.body = source_definition.to_json
      end

      handle_response(response) do |payload|
        SourceDefinition.from_payload(payload, response.headers['etag'])
      end
    end

    def update_source(collector_id, source_definition)
      response = connection.put do |req|
        req.url "/api/v1/collectors/#{collector_id}/sources/#{source_definition.id}"
        req.body = source_definition.to_json
        req.headers['Content-Type'] = 'application/json'
        req.headers['If-Match'] = source_definition.version
      end

      handle_response(response) do |payload|
        SourceDefinition.from_payload(payload, response.headers['etag'])
      end
    end

  private

    def handle_response(response)
      payload = JSON.parse(response.body)

      raise SumoControl::Error.new(payload) if response.status >= 400

      yield payload
    end
  end
end
