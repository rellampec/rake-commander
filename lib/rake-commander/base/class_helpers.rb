class RakeCommander
  module Base
    module ClassHelpers
      NOT_USED = :no_used!.freeze

      # Helper to determine if a paramter has been used
      # @note to effectivelly use this helper, you should initialize your target
      #  paramters with the constant `NOT_USED`
      # @param val [] the value of the paramter
      # @return [Boolean] `true` if value other than `NOT_USED`, `false` otherwise
      def used_param?(val)
        val != NOT_USED
      end

      # Redefines constant `const` with `value` without triggering a warning.
      def redef_without_warning(const, value)
        self.class.send(:remove_const, const) if self.class.const_defined?(const)
        self.class.const_set(const, value)
      end

      # Defines a class and instance method for lazy resolving a class.
      def class_resolver(name, klass)
        define_singleton_method(name) { resolve_class(klass) }
        define_method(name) { self.class.resolve_class(klass) }
      end

      # Class resolver
      # @note it caches the resolved `klass`es
      # @raise [Exception] when could not resolve if `exception` is `true`
      # @param klass [Class, String, Symbol] the class to resolve
      # @param source_class [Class] when the reference to `klass` belongs to a different inheritance chain.
      # @param exception [Boolean] if it should raise exception when could not resolve
      # @return [Class] the `Class` constant
      def resolve_class(klass, source_class: self, exception: true)
        @resolved ||= {}
        @resolved[klass] ||=
          case klass
          when Class
            klass
          when String
            begin
              Kernel.const_get(klass)
            rescue NameError
              raise if exception
            end
          when Symbol
            source_class.resolve_class(source_class.send(klass))
          when Hash
            referrer, referred = klass.first
            resolve_class(referred, source_class: referrer, exception: exception)
          else
            raise "Unknown class: #{klass}" if exception
          end
      end

      # Helper to normalize `key` into a correct `ruby` **constant name**
      # @note it removes namespace syntax `::`
      # @param key [String, Symbol] to be normalized
      # @return [String] a correct constant name
      def to_constant(key)
        key.to_s.strip.split(/::/).compact.map do |str|
          str.slice(0).upcase + str.slice(1..-1)
        end.join("").split(/[-_ :]+/i).compact.map do |str|
          str.slice(0).upcase + str.slice(1..-1)
        end.join("")
      end

      # Helper to create an instance variable `name`
      # @param [String, Symbol] the name of the variable
      # @reutrn [String] the name of the created instance variable
      def instance_variable_name(name)
        str = name.to_s
        str = "@#{str}" unless str.start_with?("@")
        str
      end

      # If the class for `name` exists, it returns it. Otherwise it generates it.
      # @param name [String, Symbol] the name of the new class
      # @param inherits [Class] the parent class to _inherit_ from
      # @param namespace [Class, String] an existing `constant` (class or module) the new class will be namespaced on
      # @yield [child_class] configure the new class
      # @yieldparam child_class [Class] the new class
      # @return [Class] the new generated class
      def new_class(name = "Child#{uid}", inherits: self, namespace: inherits)
        name            = name.to_s.to_sym.freeze
        class_name      = to_constant(name)

        unless target_class = resolve_class("#{namespace}::#{class_name}", exception: false)
          target_class = Class.new(inherits)
          Kernel.const_get(namespace.to_s).const_set class_name, target_class
        end

        target_class.tap do |klass|
          yield(klass) if block_given?
        end
      end

      # Finds all child classes of the current class.
      # @param parent_class [Class] the parent class we want to find children of.
      # @param direct [Boolean] it will only include direct child classes.
      # @param scope [nil, Array] to only look for descendants among the ones in `scope`.
      # @return [Arrary<Class>] the child classes in hierarchy order.
      def descendants(parent_class: self, direct: false, scope: nil)
        scope ||= ObjectSpace.each_object(::Class)
        return [] if scope.empty?
        scope.select do |klass|
          klass < parent_class
        end.sort do |k_1, k_2|
          next -1 if k_2 < k_1
          next  1 if k_1 < k_2
          0
        end.tap do |siblings|
          if direct
            siblings.reject! do |si|
              siblings.any? {|s| si < s}
            end
          end
        end
      end

      # @param parent_class [Class] the parent class we want to find children of.
      # @param direct [Boolean] it will only include direct child classes.
      # @return [Boolean] `true` if the current class has child classes, and `false` otherwise.
      def descendants?(parent_class: self, direct: false)
        !descendants(parent_class: parent_class, direct: direct).empty?
      end

      # Keeps track on class instance variables that should be inherited by child classes.
      # @note
      #   - subclasses will inherit the value as is at that moment
      #   - any change afterwards will be only on the specific class (in line with class instance variables)
      #   - adapted from https://stackoverflow.com/a/10729812/4352306
      # TODO: this separates the logic of the method to the instance var. Think if would be possible to join them somehow.
      def inheritable_class_vars(*vars)
        @inheritable_class_vars ||= [:inheritable_class_vars]
        @inheritable_class_vars += vars
      end

      # Builds the attr_reader and attr_writer of `attrs` and registers the associated instance variable as inheritable.
      def inheritable_attrs(*attrs, add_accessors: false)
        if add_accessors
          attrs.each do |attr|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              class << self; attr_accessor :#{attr} end
            RUBY
          end
        end
        inheritable_class_vars(*attrs)
      end

      # This callback method is called whenever a subclass of the current class is created.
      # @note
      #   - values of the instance variables are copied as they are (no dups or clones)
      #   - the above means: avoid methods that change the state of the mutable object on it
      #   - mutating methods would reflect the changes on other classes as well
      #   - therefore, `freeze` will be called on the values that are inherited.
      def inherited(subclass)
        super.tap do
          inheritable_class_vars.each do |var|
            instance_var = instance_variable_name(var)
            value        = instance_variable_get(instance_var)
            subclass.instance_variable_set(instance_var, value.freeze)
          end
        end
      end
    end
  end
end
