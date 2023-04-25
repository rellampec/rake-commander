class RakeCommander
  module Patcher
    module Application
      module TopLevelMethod
        include RakeCommander::Patcher::Base

        class << self
          def target
            Rake::Application
          end

          def patch_prepend(_invoked_by)
            return unless target_defined?
            Rake::Application.prepend Patch
          end

          def target_defined?
            return true if defined?(target)
            puts "Warning (#{self}): undefined target #{target}"
            false
          end
        end

        module Patch
          include RakeCommander::Patcher::Debug

          # To preserve `rake` as main executable, as the `RunMethod::Patch` is applied only
          # when `Rake::Application` requires the `Rakefile` that loads `rake-commander`,
          # we need to:
          #   1. Intercept the execution on the next stage of the `Rake::Application#run` command,
          #     [the `top_level` call](https://github.com/ruby/rake/blob/48e798484babf725b0562cc417986da513e5d0ae/lib/rake/application.rb#L82),
          #     and **re-launch** the rake application (so it only receives the `ARGV` cut that the main patch provides)
          #   2. Ensure that **re-launch** is done only once.
          #   3. Ensure that it does `exit(0)` to the original running application.
          def top_level
            unless @rake_commander_run_argv_patch
              @rake_commander_run_argv_patch = true
              RakeCommander.relaunch_rake_application
              # Should not reach this point
            end
            rake_comm_debug "T O P   L E V E L   ( p a t c h    a c t i v e )", "\n", num: 2, pid: true
            rake_comm_debug "  ---> Known tasks: #{tasks.map(&:name).join(", ")}"
            super
          end
        end

        module ClassMethods
          include RakeCommander::Patcher::Debug

          # Reloading `Rakefile` has drawbacks around `require` only being launched once per
          # dependency. Apparently some tasks of some gems are installed at `require` run-time.
          # This requires to keep known tasks when we switch the application.
          def relaunch_rake_application
            prev_rake_app = Rake.application
            rake_comm_debug "R A K E   R E L A U N C H   ( p a t c h    i n a c t i v e )", "\n", num: 2, pid: true
            rake_comm_debug "  ---> Known tasks: #{prev_rake_app.tasks.map(&:name).join(", ")}"
            Rake.application = Rake::Application.new
            rake_comm_debug "N e w   R a k e  A p p", "\n", num: 4, pid: true
            RakeCommander.self_load_reset
            Rake.application.run #RakeCommander.argv_rake_native_arguments(ARGV)
            rake_comm_debug "T e r m i n a t i n g   R U N", "\n", num: 3, pid: true
            exit(0)
          end

          private

          def rake_reparse_argv(argv = ARGV)
            RakeCommander.argv_rake_native_arguments(argv)
          end
        end
      end
    end
  end
end
