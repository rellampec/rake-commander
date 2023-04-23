class RakeCommander::Custom::Chained < RakeCommander
  namespace :examples

  desc 'A task you want to chain to'
  task :chained

  option '-s', '--say [SOMETHING]', "It says 'something'", default: %q(I don't know what to "say"...)

  def task(*_args)
    puts "Chained task has been called!!"
    puts options[:s] if options[:s]
  end
end
