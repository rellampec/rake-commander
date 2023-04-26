module Examples
  module Libs
    module ShellHelpers
      SHELL_METHODS = %I[system back_quotes x spawn exec fork_exec pipe].freeze

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
  end
end
