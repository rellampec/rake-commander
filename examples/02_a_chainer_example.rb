require_relative 'libs/shell_helpers'
require_relative '02_a_chainer_options_set'

class RakeCommander::Custom::Chainer < RakeCommander
  include Examples::Libs::ShellHelpers
  TARGET_TASK = 'examples:chained'.freeze

  namespace :examples

  task :chainer
  desc "Uses rake (or raked) to invoke #{TARGET_TASK}"

  # When an option as a default value defined, it is added to `options` result
  # even when the option was not invoked
  options_with_defaults true

  # Loads the otions from a pre-defined options set
  options_use RakeCommander::Custom::ChainerOptionsSet
  # Redefines the description of the option `:chain`
  option_reopen :chain, desc: "Calls: '< rake|raked > #{TARGET_TASK} task'"
  # Adds some option of its own
  str_desc  = "The method used to shell the call to examples:chained."
  str_desc << " Options: #{SHELL_METHODS.join(', ')}"
  option '-m', 'method [METHOD]', default: 'system', desc: str_desc

  def task(*_args)
    print_options if options[:b]
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

  def print_options
    puts "These are the options received:"
    pp options
  end

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
