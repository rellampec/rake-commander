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
            Rake::Application.prepend Patch if target_defined?
          end

          def target_defined?
            defined?(target).tap do |present|
              puts "Warning (#{self}): undefined target #{target}" unless present
            end
          end
        end

        module Patch
          # To extend the command line syntax we need to patch `Rake`, provided that
          # this gem's extended options are not in `argv` when `Rake` processes it.
          # @note This patch only works fine if `Rake.application.run` is **invoked after****
          #   **`RakeCommander` has been required**.
          #   * So by itself alone it allows to use `raked` executable that this gem provides.
          def run(argv = ARGV)
            super(RakeCommander.argv_rake_native_arguments(argv))
          end
        end
      end
    end
  end
end
