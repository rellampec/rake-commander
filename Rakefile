require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "yard"
require "redcarpet"

# Install examples
#puts "R a k e f i l e   L o a d i n g . . ."
require_relative 'lib/rake-commander'
RakeCommander::Patcher.debug = true
Dir["examples/*_example.rb"].sort.each {|file| require_relative file }
RakeCommander.self_load
#puts "R a k e f i l e   L o a d e d  ! !"

desc "run the specs"
RSpec::Core::RakeTask.new(:spec)

desc "run rspec showing backtrace"
RSpec::Core::RakeTask.new(:spec_trace) do |task|
  task.rspec_opts = ['--backtrace']
end

desc "run rspec stopping on first fail, and show backtrace"
RSpec::Core::RakeTask.new(:spec_fast) do |task|
  task.rspec_opts = ['--fail-fast', '--backtrace']
end

# default task name is yard
desc "Yard: generate all the documentation"
YARD::Rake::YardocTask.new(:doc) do |t|
  #t.files = ['lib/**/*.rb']
end

task default: [:spec]
task rspec_trace: :spec_trace
task rspec_fast: :spec_fast
