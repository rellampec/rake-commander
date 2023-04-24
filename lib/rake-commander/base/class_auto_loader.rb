class RakeCommander
  module Base
    # Helpers for dynamic object loading based on class declaration
    # @note
    #   - this helpers aim to boost the usage of the ruby language in complex api configurations.
    module ClassAutoLoader
      include RakeCommander::Base::ClassHelpers

      # To enable the class autoloader, you should use this  method
      def autoloads_children_of(klass)
        class_resolver :autoloader_class, klass
        @autoloaded_class = klass
      end

      # Resolves the class `autoloader_class` if it has been defined via `autoloads_children_of`
      def autoloaded_class
        return nil unless @autoloaded_class
        autoloader_class
      end

      # To which restricted namespaces this class autoloads from
      def autoloaded_namespaces(type = :include)
        @autoloaded_namespaces       ||= {}
        @autoloaded_namespaces[type] ||= []
      end

      # To restrict which namespaces it is allowed to load from
      def autoload_namespace(*namespaces)
        _autoload_namespace(:include, *namespaces)
      end

      # To ignore certain namespaces this class should not autoload from
      def autoload_namespace_ignore(*namespaces)
        _autoload_namespace(:ignore, *namespaces)
      end

      def _autoload_namespace(type, *namespaces)
        autoloaded_namespaces(type).concat(namespaces) unless namespaces.empty?
      end

      # @param constant [Class, String] a class or namespace we want to check auto-load entitlement thereof.
      # @return [Boolean] determines if a given namespace is entitled for autoloading
      def autoload_class?(constant)
        constants = constant.to_s.split("::").compact
        autoload = true
        unless autoloaded_namespaces(:include).empty?
          autoload = autoloaded_namespaces(:include).any? do |ns|
            ns.to_s.split("::").compact.zip(constants).all? {|(r, c)| r == c}
          end
        end
        unless autoloaded_namespaces(:ignore).empty?
          autoload &&= autoloaded_namespaces(:ignore).none? do |ns|
            ns.to_s.split("::").compact.zip(constants).all? {|(r, c)| r == c}
          end
        end
        autoload
      end

      # As children are loaded as they are declared, we should not load twice same children.
      def autoloaded_children
        @autoloaded_children ||= []
      end

      # Allows to reload
      # @note it may be handy some times.
      def clear_autoloaded_children
        forget_class!(*autoloaded_children)
        @autoloaded_children = []
      end

      # Prevents already excluded childrent to enter into the loop again.
      def excluded_children
        @excluded_children ||= []
      end

      # Children classes of `autoloader_class` that have not been created an instance of.
      def unloaded_children
        return [] unless autoloaded_class
        new_detected = new_classes
        known_class!(*new_detected)
        descendants(parent_class: autoloaded_class, scope: new_detected).select do |child_class|
          !autoloaded_children.include?(child_class) && \
            !excluded_children.include?(child_class) && \
            autoload_class?(child_class)
        end
      end

      # It loads/creates a new instance of children classes pending to be loaded.
      # @return [Boolean] `true` if there were children loaded, `false` otherwise.
      def autoload_children(object = nil)
        return false if !autoloaded_class || @loading_children
        pending_children = unloaded_children
        return false if pending_children.empty?
        @loading_children = true
        pending_children.each do |klass|
          exclude = false
          child   = object ? klass.new(object) : klass.new
          yield(child) if block_given?
        rescue TypeError
          # Can't create from this class (must be the singleton class)
          exclude = true
          excluded_children.push(klass)
        ensure
          autoloaded_children.push(klass) unless exclude
        end
        @loading_children = false
        true
      end

      # Known namespaces serves the purpose to discover recently added namespaces
      #   provided that the namespace discovery is optimized
      def known_classes
        @known_classes ||= []
      end

      # Add to known namespaces
      def known_class!(*classes)
        known_classes.concat(classes)
        self
      end

      # Forget namespaces
      def forget_class!(*classes)
        @known_classes = known_classes - classes
        self
      end

      # List all new namespaces
      def new_classes
        ObjectSpace.each_object(::Class).to_a - known_classes
      end
    end
  end
end
