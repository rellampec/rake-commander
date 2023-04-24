require_relative 'patcher/helpers'
require_relative 'patcher/debug'
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

      def debug=(value)
        @debug = !!value
      end

      def debug?
        @debug = false unless instance_variable_defined?(:@debug)
        @debug
      end
    end
  end
end
