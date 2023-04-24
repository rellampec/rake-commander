class RakeCommander
  module Patcher
    module Application
      module RunMethod
        include RakeCommander::Patcher::Base

        class << self
          def target
            Rake::Application
          end

          def patch_prepend(_invoked_by)
            if target_defined?
              Rake::Application.prepend Patch
            end
          end

          def target_defined?
            defined?(target).tap do |present|
              puts "Warning (#{self}): undefined target #{target}" unless present
            end
          end
        end

        module Patch
          include RakeCommander::Patcher::Debug

          # To extend the command line syntax we need to patch `Rake`, provided that
          # this gem's extended options are not in `argv` when `Rake` processes it.
          # @note we define an instance variable so we can know if the patch was applied when it started.
          # @note This patch only works fine if `Rake::Application#run` is **invoked after****
          #   **`RakeCommander` has been required**.
          #   * So by itself alone it allows to use `raked` executable that this gem provides.
          def run(argv = ARGV)
            rake_comm_debug "R U N  !", "\n", num: 1, pid: true
            rake_comm_debug "  ---> ARGV: [#{argv.map{|a| "'#{a}'"}.join(', ')}]"
            rake_comm_debug "  ---> Command: #{$0}"
            @rake_commander_run_argv_patch = true unless instance_variable_defined?(:@rake_commander_run_argv_patch)
            RakeCommander.self_load
            super(RakeCommander.argv_rake_native_arguments(argv))
          end
        end
      end
    end
  end
end
