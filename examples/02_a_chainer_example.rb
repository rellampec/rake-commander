class RakeCommander::Custom::Chainer < RakeCommander
  namespace :examples

  # Symbol Array
  SHELL_METHODS = %I[system back_quotes x spawn exec fork_exec pipe].freeze
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

  # https://stackoverflow.com/a/37329716/4352306
  def shell(cmd, method: :system)
    method = method.to_sym
    case method
    when :system
      success = system(cmd)
      puts "* #{success ? "Succeded in" : "Failed to"} running '#{cmd}'"
    when :back_quotes, :x
      result = `#{cmd}`
      puts result
      #%x(#{cmd})
    when :spawn # like Kernel.system but with no wait
      pid = Process.spawn(cmd)
      puts "* new child process (pid: #{pid}). Will wait..."
      Process.wait(pid)
      puts "* child process finished (pid: #{pid})"
    when :exec
      exec cmd
      # Flow does not reach here
    when :fork_exec
      for_exec(cmd)
    when :pipe # I/O of new process
      pipe(cmd)
    else
      raise "* unknown shell method '#{method}'"
    end
  end

  def fork_exec(cmd)
    pid = fork do
      shell(cmd, method: :exec)
    end
    puts "* new child process (pid: #{pid})"
  rescue NotImplementedError => e
    puts e
    puts "Redirecting to 'spawn'"
    shell(cmd, method: :spawn)
  end

  def pipe(cmd)
    IO.popen(host_shell_command, 'r+') do |pipe|
      puts "* new child process (pid: #{pipe.pid})"
      prompt = pipe_prompt(pipe)
      pipe.puts cmd
      pipe.close_write # prevent `gets` to get stuck
      lines = pipe.readlines
      if index = lines.index {|ln| ln.include?(cmd)}
        lines = lines[index+1..]
      end
      lines.reject! {|ln| ln.start_with?(prompt)}
      lines = lines.map {|ln| ">> (pid: #{pipe.pid}) #{ln}"}
      puts lines
    end
  end

  def pipe_prompt(pipe, prompt: ':>$ ')
    if Gem::Platform.local.os == "mingw32"
      pipe.puts "function prompt {\"#{prompt}\"}"
    else
      pipe.puts "PS1=\"#{prompt}\""
    end
    prompt
  end

  def host_shell_command
    if Gem::Platform.local.os == "mingw32"
      "powershell -noprofile -noninteractive"
    else
      'sh'
    end
  end
end
