class RakeCommander::Custom::Chained < RakeCommander::Custom::Chainer
  #namespace :examples # <-- inherited
  desc 'A task you want to chain to'
  task :chained

  option_reopen :s, "It says 'something'", default: %q(I don't know what to "say"...)
  option_remove :c, :w, :method

  def task(*_args)
    puts "Called !!"
    puts options[:s] if options[:s]
  end
end
