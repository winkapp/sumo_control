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
      connection.get "/api/v1/collectors/#{collector_id}/sources/#{source_id}"
    end

    def create_source(collector_id, source_definition)
      connection.post do |req|
        req.url "/api/v1/collectors/#{collector_id}/sources"
        req.headers['Content-Type'] = 'application/json'
        req.body = source_definition.to_json
      end
    end

    def update_source(collector_id, source_id, source, version)
      connection.put do |req|
        req.url "/api/v1/collectors/#{collector_id}/sources/#{source_id}"
        req.body = {:source => source}.to_json
        req.headers['Content-Type'] = 'application/json'
        req.headers['If-Match'] = version
      end
    end
  end
end
