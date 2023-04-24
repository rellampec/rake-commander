class RakeCommander::Custom::Chainer < RakeCommander
  namespace :examples

  desc 'A task that uses rake or raked to invoke another task'
  task :chainer

  # When an option as a default value defined, it is added to `options` result
  # even when the option was not invoked
  options_with_defaults true

  option :c, :chain, TrueClass, desc: "Calls: '< rake|raked > examples:chained task'"
  option :w, '--with CALLER', default: 'raked', desc: "Specifies if should invoke with 'rake' or 'raked'"
  option '-m', '--method [METHOD]', default: 'system', desc: "The method used to shell the call to examples:chained"
  option '-s', '--say [SOMETHING]', "It makes chainer say 'something'"
  option '-b', '--debug', TrueClass, 'Whether to add additional context information to messages'

  def task(*_args)
    if options[:c]
      with = options[:w] == 'rake' ? 'rake' : 'bin\raked'
      cmd  = "#{with} examples:chained"
      cmd << " -- --say \"#{options[:s]}\"" if options[:s]
      cmd << " --debug" if options[:b]

      puts "Calling --> '#{cmd}'"
      shell(cmd, method: options[:m])
    else
      puts "Nothing to do :|"
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

  def shell(cmd, method: :system)
    method =  method.to_sym
    case method
    when :system
      success = system(cmd)
      puts "* #{success ? "Succeded in" : "Failed to"} running '#{cmd}'"
    when :spawn # like Kernel.system but with no wait
      pid = Process.spawn(cmd)
      puts "* new child process (pid: #{pid})"
    when :back_quotes
      `#{cmd}`
      #%x(#{cmd})
    when :exec
      exec cmd
      # Flow does not reach here
    when :exec_fork
      pid = fork {
        shell(cmd, method: :exec)
      }
      puts "* new child process (pid: #{pid})"
    when :popen # I/O of new process
      IO.popen(host_shell_command, 'r+') do |pipe|
        puts "* new child process (pid: #{pipe.pid})"
        prompt = pipe_prompt(pipe)
        pipe.puts cmd
        pipe.close_write # prevent `gets` to get stuck
        lines = pipe.readlines
        if index = lines.index {|line| line.include?(cmd)}
          lines = lines[index+1..]
        end
        lines.reject! {|line| line.start_with?(prompt)}
        puts lines.map {|ln| ">> (pid: #{pipe.pid}) #{ln}"}
      end
    else
      raise "* unknown shell method '#{method}'"
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
