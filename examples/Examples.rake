require 'dotenv'
require 'dotenv/load'

require_relative '../lib/rake-commander'
RakeCommander::Patcher.debug = ENV['COMMANDER_DEBUG'] == "true"
Dir["../lib/examples/*_example.rb"].sort.each {|file| require_relative file }
RakeCommander.self_load
