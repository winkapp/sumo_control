$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'sumo_control'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :faraday
  c.configure_rspec_metadata!

  c.default_cassette_options = {:record => :new_episodes}
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.color = true
  # config.fail_fast = true
  config.only_failures

  # Set logging level, change for more output during testing
  ENV['LOG_LEVEL'] = 'INFO'
end
