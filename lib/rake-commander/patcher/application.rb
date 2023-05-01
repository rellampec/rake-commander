class RakeCommander
  module Patcher
    module Application
      include RakeCommander::Patcher::Base
      require_relative 'application/top_level_resume'

      class << self
        def patch_include(base)
          base.send :include, TopLevelResume
        end
      end
    end
  end
end
