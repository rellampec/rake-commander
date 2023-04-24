class RakeCommander::Custom::Chained < RakeCommander
  namespace :examples

  desc 'A task you want to chain to'
  task :chained

  option '-s', '--say [SOMETHING]', "It says 'something'", default: %q(I don't know what to "say"...)
  option '-b', '--debug', TrueClass, 'Whether to add additional context information to messages'

  def task(*_args)
    puts "Called !!"
    puts options[:s] if options[:s]
  end

  private

  def puts(str)
    return super unless options[:b]
    super "#{app_id}   #{str}   #{thread_id}"
  end

  def app_id
    "(#{self.class.task_fullname}: #{Rake.application.object_id})"
  end

  def thread_id
    "(PID: #{Process.pid} ++ Thread: #{Thread.current.object_id})"
  end
end
