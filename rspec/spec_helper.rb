require 'bundler/setup'
require 'eco/forces'
require 'factory_bot'

# require_relative 'models'
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.expect_with :rspec do |expectations|
    #expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end
  # Enable `--only-failures` and `--next-failure` CLI options.
  config.example_status_persistence_file_path = "spec/.rspec_status"
  # config.disable_monkey_patching!
  # config.warnings = false
  # config.profile_examples = 2
  # config.order = :random
  # Kernel.srand config.seed
end

Dir[File.join(__dir__, 'rspec/**/*.rb')].each { |f| require f }
Dir[File.join(__dir__, 'factory/**/*.rb')].each { |f| require f }
