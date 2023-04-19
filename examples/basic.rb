require 'rake-commander'
class RakeCommander::Custom::Basic < RakeCommander
  namespace :example

  desc 'A simple example to get started'
  task :basic

  option '-s', '--say [SOMETHING]', "It says 'something'", default: %q(I don't know what to "say"...)
  option :d, '--folder NAME', default: '.', desc: 'Source local folder'
  option '-t', :show_time, TrueClass, desc: 'Displays the local time'

  def task(*_args)
    puts 'We got these options:'
    pp options
  end
end

RakeCommander.auto_load
