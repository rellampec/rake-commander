require_relative 'libs/shell_helpers'

class RakeCommander::Custom::Chainer < RakeCommander
  namespace :examples

  include Examples::Libs::ShellHelpers

  # Symbol Array
  TARGET_TASK   = 'examples:chained'.freeze

  desc "Uses rake (or raked) to invoke #{TARGET_TASK}"
  task :chainer


  # When an option as a default value defined, it is added to `options` result
  # even when the option was not invoked
  options_with_defaults true

  option :c, :chain, TrueClass, desc: "Calls: '< rake|raked > #{TARGET_TASK} task'"
  option :w, '--with CALLER', default: 'rake', desc: "Specifies if should invoke with 'rake' or 'raked'"
  str_desc  = "The method used to shell the call to examples:chained."
  str_desc << " Options: #{SHELL_METHODS.join(', ')}"
  option '-m', '--method [METHOD]', default: 'system', desc: str_desc
  option '-s', '--say [SOMETHING]', "It makes chainer say 'something'"
  option '-b', '--debug', TrueClass, 'Whether to add additional context information to messages'

  def task(*_args)
    if options[:c]
      cmd = "#{subcommand_base} -- #{subcommand_arguments.join(' ')}"
      puts "Calling --> '#{cmd}'"
      shell(cmd, method: options[:m])
    else
      puts "Nothing to do :|"
    end
  end

  def subcommand_base
    with = options[:w] == 'raked' ? 'bin\raked' : 'rake'
    "#{with} #{self.class::TARGET_TASK}"
  end

  def subcommand_arguments
    [].tap do |args|
      if options.key?(:s)
        str_opt  = "--say"
        str_opt << " \"#{options[:s]}\"" if options[:s]
        args << str_opt
      end
      args << "--debug" if options[:b]
    end
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
