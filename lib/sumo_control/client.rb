require 'faraday'

class SumoControl
  class Client
    API_HOST = 'https://api.sumologic.com'

    attr_reader :connection, :logger

    def initialize(user, password, logger = Logger.new('/dev/null'))
      @logger = logger
      @connection = Faraday.new(:url => API_HOST) do |r|
        r.adapter Faraday.default_adapter
      end
      @connection.basic_auth(user, password)
    end

    def sources(collector_id)
      url = "/api/v1/collectors/#{collector_id}/sources"
      log_request(url)

      response = connection.get url

      handle_response(response) do |payload|
        payload["sources"].map{|source| SourceDefinition.from_payload(source)}
      end
    end

    def source(collector_id, source_id)
      url = "/api/v1/collectors/#{collector_id}/sources/#{source_id}"
      log_request(url)

      response = connection.get url

      handle_response(response) do |payload|
        SourceDefinition.from_payload(payload['source'], response.headers['etag'])
      end
    end

    def create_source(collector_id, source_definition)
      url = "/api/v1/collectors/#{collector_id}/sources"
      log_request(url, source_definition)

      response = connection.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = source_definition.to_json
      end

      handle_response(response) do |payload|
        SourceDefinition.from_payload(payload['source'], response.headers['etag'])
      end
    end

    def update_source(collector_id, source_definition)
      url = "/api/v1/collectors/#{collector_id}/sources/#{source_definition.id}"
      log_request(url, source_definition)

      response = connection.put do |req|
        req.url url
        req.body = source_definition.to_json
        req.headers['Content-Type'] = 'application/json'
        req.headers['If-Match'] = source_definition.version
      end

      handle_response(response) do |payload|
        SourceDefinition.from_payload(payload['source'], response.headers['etag'])
      end
    end

    def delete_source(collector_id, source_definition)
      id = source_definition.respond_to?(:id) ? source_definition.id : source_definition
      url = "/api/v1/collectors/#{collector_id}/sources/#{id}"
      log_request(url)

      response = connection.delete url

      log_response(response)
    end

  private

    def log_request(url, object = nil)
      if object
        logger.debug("POST #{url}")
        logger.debug("Body: #{JSON.pretty_generate(object.to_h)}")
      else
        logger.debug("GET #{url}")
      end
    end

    def log_response(response)
      logger.debug("Request Status: #{response.status}")

      if response.body.strip.empty?
        logger.debug("No body")
      else
        logger.debug("Body: #{response.body}")
      end
    end

    def handle_response(response)
      log_response(response)
      payload = JSON.parse(response.body)

      raise SumoControl::Error.new(payload) if response.status >= 400

      yield payload if block_given?
    end
  end
end
