$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'sumo_control'
require 'vcr'
require 'pry-debugger'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :faraday
  c.configure_rspec_metadata!

  c.default_cassette_options = {:record => :new_episodes}
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.extend VCR::RSpec::Macros

  config.order = 'random'
end
