require_relative 'patcher/helpers'
require_relative 'patcher/base'
require_relative 'patcher/application'
class RakeCommander
  module Patcher
    extend RakeCommander::Patcher::Helpers
    include RakeCommander::Patcher::Base

    class << self
      def patch_include(base)
        base.send :include, Application
      end
    end
  end
end
