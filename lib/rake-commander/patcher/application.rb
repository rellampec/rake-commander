class RakeCommander
  module Patcher
    module Application
      include RakeCommander::Patcher::Base
      require_relative 'application/run_method'
      require_relative 'application/top_level_method'

      class << self
        def patch_include(base)
          base.send :include, RunMethod
          base.send :include, TopLevelMethod
        end
      end
    end
  end
end
