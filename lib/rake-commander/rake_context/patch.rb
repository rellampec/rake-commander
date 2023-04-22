class RakeCommander
  module RakeContext
    # To extend the command line syntax we need to patch `Rake`, provided that
    # this gem's extended options are not in `argv` when `Rake` processes it.
    module Patch
      # To `prepend` to `Rake::Application`
      module Application
        def init(*args)
          if idx = RakeCommander.method_argument_idx(method(__method__).super_method, :argv)
            args[idx] = RakeCommander.argv_rake_native_arguments(args[idx])
          end
          super(*args)
        end
      end
    end
  end
end
