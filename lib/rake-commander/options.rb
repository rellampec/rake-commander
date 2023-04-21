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
        base.inheritable_attrs :banner, :options_hash, :options_with_defaults
        base.class_resolver :option_class, RakeCommander::Option
        base.extend RakeCommander::Options::Arguments
      end
    end

    module ClassMethods
      def options_hash(with_implicit: false)
        @options_hash ||= {}
        return @options_hash unless with_implicit
        @options_hash.merge(implicit_shorts)
      end

      # This covers the gap where `OptionParser` auto-generates shorts out of option names.
      # @return [Hash] with free shorts that are implicit to some option
      def implicit_shorts
        options.each_with_object({}) do |opt, implicit|
          short = opt.short_implicit
          implicit[short] = opt unless options_hash.key?(short)
        end
      end

      # @return [Array<RakeCommander::Option>]
      def options
        options_hash.values.uniq
      end

      # @return [Boolean] are there options defined?
      def options?
        !options.empty?
      end

      # Clears all the options.
      def clear_options!
        @options_hash = {}
        self
      end

      # Allows to use a set of options
      # @param override [Boolean] wheter existing options with same option name
      #   should be overriden, may they clash
      # @param options [Enumerable<RakeCommander::Option>]
      def use_options(opts, override: true)
        raise "Could not obtain list of RakeCommander::Option from #{opts.class}" unless opts = to_options(opts)
        opts.each do |opt|
          add_to_options(opt, override: override)
        end
        self
      end

      # Defines a new option or opens for edition an existing one if `reopen: true` is used.
      # @note
      #   - If override is `true`, it will with a Warning when same `short` or `name` clashes.
      def option(*args, override: true, reopen: false, **kargs, &block)
        return option_reopen(*args, override: override, **kargs, &block) if reopen
        opt = option_class.new(*args, **kargs, &block)
        add_to_options(opt, override: override)
        self
      end

      # It re-opens an option for edition. If it does not exist, it **upserts** it.
      # @note
      #   1. If `override` is `false, it will fail to change the `name` or the `short`
      #     when they are already taken by some other option.
      #   2. It will have the effect of overriding existing options
      # @note when `short` and `name` are provided, `name` takes precedence over `short`
      #   in the lookup (to identify the existing option)
      def option_reopen(*args, override: false, **kargs, &block)
        opt = option_class.new(*args, **kargs, sample: true, &block)
        ref = options_hash.values_at(opt.name, opt.short).compact.first
        return add_to_options(opt) unless ref
        replace_in_options(ref, ref.merge(opt), override: override)
      end

      # Overrides the auto-generated banner
      def banner(desc = :not_used)
        return @banner = desc unless desc == :not_used
        return @banner if @banner
        return task_options_banner if respond_to?(:task_options_banner, true)
      end

      # @return [Boolean] whether results should include options defined
      #   with a default, regarless if they are invoked
      def options_with_defaults(value = nil)
        if value.nil?
          @options_with_defaults || false
        else
          @options_with_defaults = !!value
        end
      end

      # It builds the `OptionParser` injecting the `middleware` block.
      # @return [Hash] with `short` option as `key` and final value as `value`.
      def parse_options(argv = ARGV, leftovers: [], &middleware)
        options_parser_with_results(middleware) do |options_parser|
          argv = pre_parse_arguments(argv, options: options_hash(with_implicit: true))
          leftovers.push(*options_parser.parse(argv))
        rescue OptionParser::MissingArgument => e
          klass = RakeCommander::Options::MissingArgument
          opt   = error_option(e, klass)
          msg   = opt ? "missing required argument: #{opt.name_hyphen} (#{opt.short_hyphen})" : e.message
          raise klass, msg, cause: nil
        rescue OptionParser::InvalidArgument => e
          klass = RakeCommander::Options::InvalidArgument
          opt   = error_option(e, klass)
          raise klass, e, cause: nil unless opt&.argument_required?
          msg = "missing required argument: #{opt.name_hyphen} (#{opt.short_hyphen})"
          raise OptionParser::MissingArgument, msg, cause: nil
        end.tap do |results|
          check_required_presence!(results)
        end
      end

      protected

      def error_option(e, klass)
        return false unless option_sym = klass.option_sym(e.message)
        # puts klass
        # puts e.message
        #
        # pp option_sym
        # puts "Implicit shorts:"
        # pp implicit_shorts.keys
        options_hash(with_implicit: true)[option_sym]
      end

      # @return [OptionParser] the built options parser.
      def options_parser(&middleware)
        new_options_parser do |opts|
          opts.banner = banner if banner
          # Install help explicitly
          option(:h, :help, 'Prints this help') { puts opts; exit(0) }
          free_shorts = implicit_shorts

          options.each do |opt|
            free_short = free_shorts.key?(opt.short_implicit)
            opt.add_switch(opts, implicit_short: free_short, &middleware)
          end
        end
      end

      def new_options_parser(&block)
        require 'optparse'
        OptionParser.new(&block)
      end

      def install_help(opts_parser)
        # unless options_hash.key?(:h) || options_hash.key?(:help)
        #   opts.on_tail('-h', '--help', 'Prints this help') { puts opts; exit(0) }
        # end

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
            (options_with_defaults && opt.default?) \
            || (opt.required? && opt.default?)
          end.each do |opt|
            res_def[opt.short] = opt.default
          end
        end
      end

      # It throws an exception if any of the required options
      # is missing in results
      def check_required_presence!(results)
        missing = options.select(&:required?).reject do |opt|
          results.key?(opt.short) || results.key?(opt.name)
        end
        raise RakeCommander::Options::MissingOption, missing unless missing.empty?
      end

      # @todo check that all the elements are of `option_class`
      # @return [Array<RakeCommander::Option>]
      def to_options(opts)
        case
        when opts.is_a?(Hash)
          opts.values
        when opts.is_a?(RakeCommander::Options::Set)
          opts.class.options
        when opts <= RakeCommander::Options::Set
          opts.options
        when opts.respond_to?(:to_a)
          opts.to_a
        end
      end

      # Adds to `@options_hash` the option `opt`
      # @todo add `exception` parameter, to trigger an exception
      #   when `opt` name or short are taken (and override is `false`)
      # @return [Boolean] wheter or not it succeeded adding the option.
      def add_to_options(opt, override: true)
        if prev = options_hash[opt.short]
          return false unless override
          puts "Warning: Overriding option with short '#{prev.short}' ('#{prev.name}')"
          delete_from_options(prev)
        end
        if prev = options_hash[opt.name]
          return false unless override
          puts "Warning: Overriding option with name '#{prev.name}' ('#{prev.short}')"
          delete_from_options(prev)
        end
        options_hash[opt.name] = options_hash[opt.short] = opt
        true
      end

      # Deletes an option from the `options_hash`
      def delete_from_options(opt)
        options_hash.delete(opt.short)
        options_hash.delete(opt.name)
      end

      # @return [Boolean] whether it succeeded replacing option `ref` with `opt`
      def replace_in_options(ref, opt, override: false)
        # Try to keep the same potition
        options_hash[ref.short] = options_hash[ref.name] = nil
        add_to_options(opt, override: override).tap do |success|
          next options_hash[ref.short] = options_hash[ref.name] = ref unless success
          delete_empty_keys(options_hash)
        end
      end

      # Deletes all keys with `nil` as value
      def delete_empty_keys(h)
        h.dup.each do |k, v|
          next unless v.nil?
          h.delete(k)
        end
      end
    end

    def options(argv = ARGV)
      @options ||= self.class.parse_options(argv, leftovers: options_leftovers)
    end

    def options_leftovers
      @options_leftovers ||= []
    end
  end
end

require_relative 'options/error'
require_relative 'options/set'
