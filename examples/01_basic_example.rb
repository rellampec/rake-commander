class RakeCommander::Custom::BasicExample < RakeCommander
  namespace :examples

  desc 'A simple example to get started'
  task :basic

  #banner "Usage: basic:example -- [options]"
  option '-w', :show_time, TrueClass, desc: 'Displays the local time'
  option :z, '--timezone', TrueClass, default: false, required: true
  option :o, '--hello NAME', String, desc: 'It greets.'
  option '-s', '--say [SOMETHING]', "It says 'something'", default: %q(I don't know what to "say"...)
  option :d, '--folder NAME', default: '.', desc: 'Source local folder', required: true
  option '-e', :'--enviro ENV', 'The target environment to run this task', required: true
  option :v, :debug, TrueClass, 'Shows the parsed options'
  option :V, '[no-]verbose', 'Verbosity', TrueClass
  #option :f, :folder, required: false, reopen: true

  def task(*_args)
    puts "Hello #{options[:o]}!!" if options[:o]
    if options[:v]
      puts 'We got these options:'
      pp options
    end
    puts Time.now.strftime('%d %b at %H:%M') if options[:w]
    puts Time.now.zone                       if options[:z]
    puts options[:s]                         if options.key?(:s)
  end
end
