require 'faraday'

module SumoControl
  class Client
    API_HOST = 'https://api.sumologic.com'

    attr_reader :connection

    def initialize(user, password)
      @connection = Faraday.new(:url => API_HOST) do |r|
        r.response :logger
        r.adapter Faraday.default_adapter
      end

      @connection.basic_auth(user, password)

      @connection
    end
  end
end
