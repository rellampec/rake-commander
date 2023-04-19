require_relative File.join(__dir__, '../lib/rake-commander')
class RakeCommander::Custom::Basic < RakeCommander
  namespace :basic

  desc 'A simple example to get started'
  task :example

  banner "Usage: basic:example -- [options]"
  option '-s', '--say [SOMETHING]', "It says 'something'", default: %q(I don't know what to "say"...)
  option :d, '--folder NAME', default: '.', desc: 'Source local folder', required: true
  option '-e', '--enviro ENV', 'The target environment to run this task', required: true
  option '-t', :show_time, TrueClass, desc: 'Displays the local time'
  option :v, :debug, TrueClass, 'Shows the parsed options'

  def task(*_args)
    if options[:v]
      puts 'We got these options:'
      pp options
    end
    puts Time.now.strftime('%d %b at %H:%M') if options[:t]
    puts options[:s] if options.key?(:s)
  end
end

RakeCommander.self_load
Rake::Task[:'basic:example'].invoke
# ruby basic.rb -- -v -d /some/folder -t

#RakeCommander::Custom::Basic.parse_options %w[--help]
#RakeCommander::Custom::Basic.parse_options %w[-d]
