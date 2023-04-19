require_relative 'rake_context/wrapper'

class RakeCommander
  module RakeTask
    NAMESPACE_DELIMITER = /:/.freeze
    RAKE_END_COMMAND    = '--'.freeze
    INHERITABLE_ATTRS   = [:namespace].freeze

    class << self
      def included(base)
        super(base)
        base.extend ClassMethods
        base.inheritable_attrs(*INHERITABLE_ATTRS)
      end
    end

    module ClassMethods
      include RakeCommander::Base::ClassHelpers

      # The rake context wrapper (to invoke rake commands)
      def rake
        @rake ||= RakeCommander::RakeContext::Wrapper.new
      end

      # Does the final rake `task` definition
      def install_task(&task_method)
        raise "Expected task_block." unless task_method

        # ensure options are parsed before calling task
        # and that ARGV is only parsed after `--`
        task_method = invoke_options_before_task(&task_method) if options?

        if namespaced?
          namespaced do
            rake.desc desc
            rake.task task, &task_method
          end
        else
          rake.desc desc
          rake.task task, &task_method
        end
      end

      # Give a name to the task
      # @return [Symbol] the task name
      def task(name = nil)
        return @task if name.nil?
        @task = name.to_sym
      end

      # Give a description to the task
      # @return [String] the description of the task
      def desc(str = nil)
        return @desc if str.nil?
        @desc = str.to_s
      end

      # It can be hierarchical by using `NAMESPACE_DELIMITER`
      # @return [String] the namespace defined for this `RakeCommander` class.
      def namespace(name = nil)
        return @namespace if name.nil?
        @namespace = namespace_str(name)
      end

      # Is this rake context namespaced?
      # @note Rake allows to namespace tasks (i.e. `task :"run:this"`)
      #   Although supported by this integration, namespace detection
      #   is left to the core `rake` gem. This method will return `false`.
      # @return [Boolean]
      def namespaced?
        !!namespace
      end

      # It builds the nested `namespace` **rake** blocks
      def namespaced(name = namespace, &block)
        spaces = namespace_split(name)
        top    = spaces.shift
        block  = spaces.reverse.reduce(block) do |blk, nm|
          namespace_block(nm, &blk)
        end
        rake.namespace top, &block
      end

      protected

      # Converstion of `namespace` name to string
      # @return [String]
      def namespace_str(name)
        name = name.to_s   if name.is_a?(Symbol)
        name = name.to_str if name.respond_to?(:to_str)
        raise ArgumentError, "Expected a String or Symbol for a namespace name. Given: #{name.class}" unless name.is_a?(String)
        name
      end

      # @return [String, NilClass] generic banner for options
      def task_options_banner
        str_space = respond_to?(:namespace)? "#{namespace}:" : ''
        str_task  = respond_to?(:task)     ? "Usage: #{str_space}#{task} -- [options]" : nil
      end

      private

      # Split into `Array` the namespace based on `NAMESPACE_DELIMITER`
      # @return [Array<String>]
      def namespace_split(name)
        namespace_str(name).split(NAMESPACE_DELIMITER)
      end

      # Helper to build the rake `namespace` blocks
      # @return [Proc] which will invoke `namspace name` from the global context when called.
      def namespace_block(name, &block)
        rake.context do
          proc { namespace name, &block }
        end
      end

      # Rake command ends at `--` (`RAKE_END_COMMAND`).
      # We only want to parse the options that come afterwards
      # @note without this approach, it will throw `OptionParser::InvalidOption` error
      # @return [Proc]
      def invoke_options_before_task(&task_method)
        object = eval('self', task_method.binding, __FILE__, __LINE__)
        return task_method unless object.is_a?(self)
        proc do |*args|
          argv = ARGV
          if idx = argv.index(RAKE_END_COMMAND)
            argv = argv[idx+1..-1]
          end
          object.options(argv)
          task_method.call(*args)
        end
      end
    end

    def initialize
      super if defined?(super)
      install_task
    end

    # def task
    #   raise "You should override/define this method"
    # end

    protected

    def install_task
      return unless task_block = task_method
      self.class.install_task(&task_block)
    end

    def task_method
      method(:task)
    rescue NameError
      nil
    end
  end
end
