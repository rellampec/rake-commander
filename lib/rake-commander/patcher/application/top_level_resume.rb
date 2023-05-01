class RakeCommander
  module Patcher
    module Application
      module TopLevelResume
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
          # To preserve `rake` as main executable, as the `RunMethod::Patch` is applied only
          # when `Rake::Application` requires the `Rakefile` that loads `rake-commander`,
          # we technically only need to fix the `top_level_tasks` that have been detected.
          def top_level
            argv = RakeCommander.argv_rake_native_arguments(ARGV)
            Rake.application.send(:collect_command_line_tasks, argv)
            super
          end
        end
      end
    end
  end
end
