require_relative 'options/name'
require_relative 'options/arguments'
require_relative 'option'

class RakeCommander
  module Options
    class << self
      def included(base)
        super(base)
        base.extend RakeCommander::Base::ClassHelpers
        base.extend ClassMethods
        base.inheritable_attrs :banner, :options_hash, :results_with_all_defaults
        base.extend RakeCommander::Options::Arguments
      end
    end

    module ClassMethods
      def options_hash
        @options_hash ||= {}
      end

      def options
        options_hash.values.uniq
      end

      def options?
        !options.empty?
      end

      def clear_options!
        @options_hash = {}
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
      def banner(desc = :not_used)
        return @banner = desc unless desc == :not_used
        return @banner if @banner
        return task_options_banner if respond_to?(:task_options_banner, true)
      end

      # @return [Boolean] whether results should include options defined
      #   with a default, regarless if they are invoked
      def results_with_all_defaults(value = nil)
        if value.nil?
          @results_with_all_defaults || false
        else
          @results_with_all_defaults = !!value
        end
      end

      # It builds the `OptionParser` injecting the `middleware` block.
      # @return [Hash] with `short` option as `key` and final value as `value`.
      def parse_options(argv = ARGV, leftovers: [], &middleware)
        left_overs = []
        options_parser_with_results(middleware) do |options_parser|
          argv = pre_parse_arguments(argv, options_hash)
          leftovers.push(*options_parser.parse(argv))
        rescue OptionParser::MissingArgument => e
          raise RakeCommander::Options::MissingArgument, e, cause: nil
        rescue OptionParser::InvalidArgument => e
          error = RakeCommander::Options::InvalidArgument
          error = error.new(e)
          if (opt = options_hash[error.option_sym]) && opt.argument_required?
            msg = "missing required argument: #{opt.name_hyphen} (#{opt.short_hyphen})"
            raise RakeCommander::Options::MissingArgument, msg, cause: nil
          else
            raise error, e, cause: nil
          end
        end.tap do |results|
          check_required_presence!(results)
        end
      end

      protected

      # @return [OptionParser] the built options parser.
      def options_parser(&middleware)
        new_options_parser do |opts|
          opts.banner = banner if banner
          options.each {|opt| opt.add_switch(opts, &middleware)}
        end
      end

      def new_options_parser(&block)
        require 'optparse'
        OptionParser.new(&block)
      end

      private

      # Expects a block that should do the final call to `#parse`
      def options_parser_with_results(middleware)
        result_defaults.tap do |result|
          results_collector = proc do |value, default, short, name|
            middleware&.call(value, default, short, name)
            result[short] = value.nil?? default : value
          end
          options_parser = options_parser(&results_collector)
          yield(options_parser)
        end
      end

      # Based on `required` options, it sets the `default`
      def result_defaults
        {}.tap do |res_def|
          options.select do |opt|
            (results_with_all_defaults && opt.default?) \
            ||  (opt.required? && opt.default?)
          end.each do |opt|
            res_def[opt.short] = opt.default
          end
        end
      end

      # It throws an exception if any of the required options
      # is missing in results
      def check_required_presence!(results)
        missing = options.select do |opt|
          opt.required?
        end.reject do |opt|
          results.key?(opt.short) || results.key?(opt.name)
        end
        raise RakeCommander::Options::MissingOption.new(missing) unless missing.empty?
      end

      def add_to_options(opt)
        if prev = options_hash[opt.short]
          puts "Warning: Overriding option with short '#{prev.short}' ('#{prev.name}')"
          options_hash.delete(prev.short)
          options_hash.delete(prev.name)
        end
        if prev = options_hash[opt.name]
          puts "Warning: Overriding option with name '#{prev.name}' ('#{prev.short}')"
          options_hash.delete(prev.short)
          options_hash.delete(prev.name)
        end
        options_hash[opt.name] = options_hash[opt.short] = opt
      end
    end

    def options(argv = ARGV)
      @options ||= self.class.parse_options(argv, leftovers: self.options_leftovers)
    end

    def options_leftovers
      @options_leftovers ||= []
    end
  end
end

require_relative 'options/error'
require_relative 'options/set'
