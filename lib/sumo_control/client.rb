require 'faraday'

class SumoControl
  class Client
    API_HOST = 'https://api.us2.sumologic.com'

    attr_reader :connection

    # @param [String] access_id - Sumo API Access ID
    # @param [String] access_key - Sumo API Access Key
    def initialize(access_id, access_key, logger=nil)
      if logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger.const_get(ENV['LOG_LEVEL'].upcase) rescue nil || Logger::INFO
      else
        @logger = logger
      end
      @connection = Faraday.new(:url => API_HOST) do |r|
        r.adapter Faraday.default_adapter
      end
      @connection.basic_auth(access_id, access_key)
    end

    # @return [Array<SumoControl::CollectorDefinition>] Collector Definitions
    def collectors
      url = '/api/v1/collectors'
      log_request(url)

      response = connection.get url

      handle_response(response) do |payload|
        payload['collectors'].map{|source| CollectorDefinition.from_payload(source)}
      end
    end

    # @return [SumoControl::CollectorDefinition] Collector Definition
    def collector(collector_id)
      url = "/api/v1/collectors/#{collector_id}"
      log_request(url)

      response = connection.get url

      handle_response(response) do |payload|
        CollectorDefinition.from_payload(payload['collector'], response.headers['etag'])
      end
    end

    # @param [SumoControl::CollectorDefinition] collector_definition
    # @return [SumoControl::CollectorDefinition] Created Collector Definition
    def create_collector(collector_definition)
      url = '/api/v1/collectors'

      log_request(url, collector_definition, 'POST')

      response = connection.post do |request|
        request.url url
        request.headers['Content-Type'] = 'application/json'
        request.body = collector_definition.to_json
      end

      handle_response(response) do |payload|
        CollectorDefinition.from_payload(payload['collector'], response.headers['etag'])
      end
    end

    # @param [SumoControl::CollectorDefinition] collector_definition
    # @return [SumoControl::CollectorDefinition] Updated Collector Definition
    def update_collector(collector_definition)
      collector_definition.identify_as(remote_collector_definition(collector_definition)) if collector_definition.id.nil?

      url = "/api/v1/collectors/#{collector_definition.id}"
      log_request(url, collector_definition, 'PUT')

      response = connection.put do |request|
        request.url url
        request.body = collector_definition.to_json
        request.headers['Content-Type'] = 'application/json'
        request.headers['If-Match'] = collector_definition.version
      end

      handle_response(response) do |payload|
        CollectorDefinition.from_payload(payload['collector'], response.headers['etag'])
      end
    end

    # @param [SumoControl::CollectorDefinition] collector_definition
    def delete_collector(collector_definition)
      collector_definition.identify_as(remote_collector_definition(collector_definition)) if collector_definition.id.nil?
      url = "/api/v1/collectors/#{collector_definition.id}"
      log_request(url, nil, 'DELETE')

      response = connection.delete url

      log_response(response)
    end

    # @param [Fixnum] collector_id
    # @return [Array<SumoControl::SourceDefinition>] Source Definitions
    def sources(collector_id)
      url = "/api/v1/collectors/#{collector_id}/sources"
      log_request(url)

      response = connection.get url

      handle_response(response) do |payload|
        payload['sources'].map{|source| SourceDefinition.from_payload(source)}
      end
    end

    # @param [Fixnum] collector_id
    # @param [Fixnum] source_id
    # @return [SumoControl::SourceDefinition] Source Definition
    def source(collector_id, source_id)
      url = "/api/v1/collectors/#{collector_id}/sources/#{source_id}"
      log_request(url)

      response = connection.get url

      handle_response(response) do |payload|
        SourceDefinition.from_payload(payload['source'], response.headers['etag'])
      end
    end

    # @param [Fixnum] collector_id
    # @param [SumoControl::SourceDefinition] source_definition
    # @return [SumoControl::SourceDefinition] Source Definition
    def create_source(collector_id, source_definition)
      url = "/api/v1/collectors/#{collector_id}/sources"
      log_request(url, source_definition, 'POST')

      response = connection.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = source_definition.to_json
      end

      handle_response(response) do |payload|
        SourceDefinition.from_payload(payload['source'], response.headers['etag'])
      end
    end

    # @param [Fixnum] collector_id
    # @param [SumoControl::SourceDefinition] source_definition
    # @return [SumoControl::SourceDefinition] Updated Source Definition
    def update_source(collector_id, source_definition)
      source_definition.identify_as(remote_source_definition(collector_id, source_definition)) if source_definition.id.nil?

      url = "/api/v1/collectors/#{collector_id}/sources/#{source_definition.id}"
      log_request(url, source_definition, 'PUT')

      response = connection.put do |request|
        request.url url
        request.body = source_definition.to_json
        request.headers['Content-Type'] = 'application/json'
        request.headers['If-Match'] = source_definition.version
      end

      handle_response(response) do |payload|
        SourceDefinition.from_payload(payload['source'], response.headers['etag'])
      end
    end

    # @param [Fixnum] collector_id
    # @param [SumoControl::SourceDefinition] source_definition
    def delete_source(collector_id, source_definition)
      source_definition.identify_as(remote_source_definition(collector_id, source_definition)) if source_definition.id.nil?
      url = "/api/v1/collectors/#{collector_id}/sources/#{source_definition.id}"
      log_request(url, nil, 'DELETE')

      response = connection.delete url

      log_response(response)
    end

  private

    attr_reader :logger

    def log_request(url, object = nil, method = 'GET')
      logger.debug("#{method} #{url}")
      # logger.debug("Body: #{JSON.pretty_generate(object.to_h)}") unless object.nil?
    end

    def log_response(response)
      logger.debug("Response Status: #{response.status}")
      # if response.body.strip.empty?
      #   logger.debug('No body')
      # else
      #   logger.debug("Body: #{response.body}")
      # end
    end

    def handle_response(response)
      log_response(response)
      payload = JSON.parse(response.body)

      raise SumoControl::Error.new(payload) if response.status >= 400

      yield payload if block_given?
    end

    def remote_source_definition(collector_id, source_definition)
      source(collector_id, lookup_source_id(collector_id, source_definition))
    end

    def lookup_source_id(collector_id, source_definition)
      remote_source = sources(collector_id).detect{|remote_source| remote_source == source_definition}
      remote_source ? remote_source.id : -1
    end


    def remote_collector_definition(collector_definition)
      collector(lookup_collector_id(collector_definition))
    end

    def lookup_collector_id(collector_definition)
      remote_collector = collectors.detect{|remote_collector| remote_collector == collector_definition}
      remote_collector ? remote_collector.id : -1
    end
  end
end


