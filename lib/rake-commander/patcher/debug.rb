class RakeCommander
  module Patcher
    # Helpers to patch
    module Debug
      private

      # Helper for debugging
      def rake_comm_debug(msg, prefix = '', num: nil, pid: false)
        return unless RakeCommander::Patcher.debug?
        rake_comm_debug_random_object_id
        num = num ? "#{num}. " : nil
        if pid
          meta = "(PID: #{Process.pid} ++ Thread: #{Thread.current.object_id} ++ Ruby 'main': #{rake_comm_debug_main_object_id})"
          msg  = "#{prefix}( #{num}#{Rake.application.object_id})   #{msg}   #{meta}"
        elsif num
          msg  = "#{prefix}( #{num})   #{msg}   "
        end
        puts msg
      end

      def rake_comm_debug_main_object_id
        eval('self.object_id', TOPLEVEL_BINDING, __FILE__, __LINE__)
      end

      def rake_comm_debug_random_object_id
        return false if !!@rake_comm_debug_random_object_id
        @rake_comm_debug_random_object_id = Array(1..20).sample.times.map do |i|
          "#{i}".tap {|str| str.object_id}
        end
        true
      end
    end
  end
end
