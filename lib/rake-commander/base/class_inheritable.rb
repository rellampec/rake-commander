class RakeCommander
  module Base
    module ClassInheritable
      include RakeCommander::Base::ObjectHelpers

      # Builds the attr_reader and attr_writer of `attrs` and registers the associated
      # instance variable as inheritable.
      # @yield [value]
      # @yieldparam value [Variant] the value of the parent class
      # @yieldreturn the value that will be inherited by the child class
      # @param attrs [Array <Symbol>] the variable names that should be inheritable.
      # @param add_accessors [Boolean] whether attr_accessor should be invoked
      # @param deep_dup [Boolean] whether the value of the instance var should be `deep_dup`ed.
      def attr_inheritable(*attrs, add_accessors: false, deep_dup: true, &block)
        attrs = attrs.map(&:to_sym)
        inheritable_class_var(*attrs, deep_dup: deep_dup, &block)
        return unless add_accessors
        attrs.each do |attr|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            class << self; attr_accessor :#{attr} end
          RUBY
        end
        self
      end

      # @return [Boolean] whether an `var` has been declared as inheritable
      def inheritable_class_var?(var)
        inheritable_class_var.any? do |_method, definitions|
          definitions.key?(var.to_sym)
        end
      end

      # Removes from the inheritance some class variables.
      # @param attrs [Array <Symbol>] the instance variable names of the class
      #   that should NOT be inheritable.
      def attr_not_inheritable(*attrs)
        attrs.each do |attr|
          next unless method = inheritable_class_var_method(attr)
          inheritable_class_var[method].delete(attr)
        end
        self
      end

      private

      # This callback method is called whenever a subclass of the current class is created.
      def inherited(subclass)
        super.tap do
          inheritable_class_var.each do |method, definitions|
            definitions.each do |var, action|
              instance_var = instance_variable_name(var)
              value        = instance_variable_get(instance_var)
              child_value  = inherited_class_value(value, method, action, subclass)
              subclass.instance_variable_set(instance_var, child_value)
            end
          end
        end
      end

      # @return [Variant] the value that the child class will inherit
      def inherited_class_value(value, method, action, subclass)
        case method
        when :mirror
          value
        when :deep_dup
          case action
          when Proc
            action.call(value, subclass)
          when :default
            custom_deep_dup(value)
          end
        end
      end

      # Keeps track on class instance variables that should be inherited by child classes.
      # @note
      #   - adapted from https://stackoverflow.com/a/10729812/4352306
      #   - subclasses will inherit the value depending on `depep_dup` and `block` if enabled or given (respectivelly)
      #   - any change afterwards will be only on the specific class (in line with class instance variables)
      # @param see `#attr_inheritable`
      # @return [Hash] methods and variables to be inherited.
      def inheritable_class_var(*vars, deep_dup: true, &block)
        @inheritable_class_var ||= {
          mirror:   {},
          deep_dup: {}
        }.tap do |hash|
          hash[:deep_dup][:inheritable_class_var] = :default
        end
        @inheritable_class_var.tap do |_methods|
          vars.each {|var| inheritable_class_var_add(var, deep_dup: deep_dup, &block)}
        end
      end

      # Adds var to the `inheritable_class_var`
      # @param var [Symbol] the name of an instance variable of this class that should be inherited.
      def inheritable_class_var_add(var, deep_dup: true, &block)
        # Remove previous definition if present
        attr_not_inheritable(var)
        method = deep_dup || block ? :deep_dup : :mirror
        inheritable_class_var[method][var] = block || :default
        self
      end

      # @return [Symbol, NilClass]
      def inheritable_class_var_method(var)
        inheritable_class_var.each do |method, definitions|
          return method if definitions.key?(var.to_sym)
        end
        nil
      end

      # Helper to create an instance variable `name`
      # @param [String, Symbol] the name of the variable
      # @return [String] the name of the created instance variable
      def instance_variable_name(name)
        str = name.to_s
        str = "@#{str}" unless str.start_with?("@")
        str
      end
    end
  end
end
