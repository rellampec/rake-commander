require_relative 'base/class_helpers'
require_relative 'base/class_auto_loader'
require_relative 'rake_task'
require_relative 'options'

class RakeCommander
  module Base
    class << self
      def included(base)
        super(base)
        base.extend RakeCommander::Base::ClassHelpers
        base.extend RakeCommander::Base::ClassAutoLoader
        base.autoloads_children_of RakeCommander

        base.extend ClassMethods
        base.send :include, RakeTask

        base.send :include, Options
        #autoload_namespace_ignore "RakeCommander::Samples"
      end
    end

    module ClassMethods
      def self_load
        autoload_children
      end
    end
  end
end
