class RakeCommander
  module Patcher
    module Application
      include RakeCommander::Patcher::Base
      require_relative 'application/run_method'

      class << self
        def patch_include(base)
          base.send :include, RunMethod
        end
      end
    end
  end
end
