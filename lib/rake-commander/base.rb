require_relative 'base/object_helpers'
require_relative 'base/class_helpers'
require_relative 'base/class_inheritable'
require_relative 'base/class_auto_loader'
require_relative 'rake_task'
require_relative 'options'

class RakeCommander
  module Base
    class << self
      def included(base)
        super(base)
        base.extend RakeCommander::Base::ClassAutoLoader
        base.autoloads_children_of RakeCommander

        base.extend ClassMethods
        base.send :include, RakeTask
        base.send :include, Options
        #autoload_namespace_ignore "RakeCommander::Samples"
      end
    end

    module ClassMethods
      # Loads children classes by keeping a cache.
      def self_load
        autoload_children
      end

      # Clears track on any auto-loaded children
      # @note required for reload.
      def self_load_reset
        clear_autoloaded_children
      end

      # Clears the cache of autoloaded children classes and loads them again.
      def self_reload
        self_load_reset
        autoload_children
      end
    end
  end
end
