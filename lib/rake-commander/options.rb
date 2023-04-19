require_relative 'options/name'
require_relative 'option'

class RakeCommander
  module Options
    class << self
      def included(base)
        super(base)
        base.extend RakeCommander::Base::ClassHelpers
        base.extend ClassMethods
        base.inheritable_attrs :banner, :options
      end
    end

    module ClassMethods
      include RakeCommander::Base::ClassHelpers

      def options
        @options ||= {}
      end

      def options?
        !options.empty?
      end

      def clear_options!
        @options = {}
      end

      # Allows to use a set of options
      # @param options [Enumerable<RakeCommander::Option>]
      def use_options(options)
        options = options.values if options.is_a?(Hash)
        options.each do |opt|
          add_to_options(opt)
        end
        self
      end

      # Defines a new option
      # @note
      #   - It will override with a Warning options with same `short` or `name`
      def option(*args, **kargs, &block)
        opt = RakeCommander::Option.new(*args, **kargs, &block)
        add_to_options(opt)
        self
      end

      # Overrides the auto-generated banner
      def banner(desc = nil)
        return @banner if desc.nil?
        @banner = desc
      end

      # It builds the `OptionParser` injecting the `middleware` block.
      # @return [Hash] with `short` option as `key` and final value as `value`.
      def parse_options(argv = ARGV, &middleware)
        result_defaults.tap do |result|
          native_block = proc do |value, default, short, name|
            middleware&.call(value, default, short, name)
            result[short] = value.nil?? default : value
          end
          options_parser = build_options_parser(&native_block)
          args = options_parser.order!(argv) {}
          options_parser.parse!(args)
        end
      end

      private

      def build_options_parser(&middleware)
        new_options_parser do |opts|
          opts.banner = banner if banner
          options.each {|_short, opt| opt.add_switch(opts, &middleware)}
        end
      end

      def result_defaults
        {}.tap do |res_def|
          options.select do |_short, opt|
            opt.default?
          end.each do |_short, opt|
            res_def[opt.short] = opt.default
          end
        end
      end

      def new_options_parser(&block)
        require 'optparse'
        OptionParser.new(&block)
      end

      def add_to_options(opt)
        if prev = options[opt.short]
          puts "Warning: Overriding option with short '#{prev.short}' ('#{prev.name}')"
          options.delete(prev.short)
          options.delete(prev.name)
        end
        if prev = options[opt.name]
          puts "Warning: Overriding option with name '#{prev.name}' ('#{prev.short}')"
          options.delete(prev.short)
          options.delete(prev.name)
        end
        options[opt.name] = options[opt.short] = opt
      end
    end

    def options(argv = ARGV)
      @options ||= self.class.parse_options(argv)
    end
  end
end

require_relative 'options/set'
