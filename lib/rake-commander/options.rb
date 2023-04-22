require_relative 'options/name'
require_relative 'options/arguments'
require_relative 'options/result'
require_relative 'options/error'
require_relative 'option'

class RakeCommander
  module Options
    class << self
      def included(base)
        super(base)
        base.extend RakeCommander::Base::ClassHelpers
        base.extend ClassMethods
        base.inheritable_attrs :banner, :options_hash
        base.class_resolver :option_class, RakeCommander::Option
        base.send :include, RakeCommander::Options::Result
        base.send :include, RakeCommander::Options::Error
        base.send :include, RakeCommander::Options::Arguments
      end
    end

    module ClassMethods
      # List of configured options
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

      # It parses the `ARGV`.
      # @note it builds the `OptionParser` injecting the `middleware` block.
      # @return [Hash] with `short` option as `key` and final value as `value`.

      # Options
      # @note this method is extended in via the following modules:
      #   1. `RakeCommander::Options::Result`: makes the method to return a `Hash` with results,
      #     as well as captures/moves the **leftovers** to their own keyed argument.
      #   2. `RakeCommander::Options:Error`:
      # @param options_parser [Option::Parser] the options parser ready for parsing.
      # @return [Array<String>] the **leftovers** of the `OptionParser#parse` call.
      def parse_options(argv = ARGV, &middleware)
        options_parser(&middleware).parse(argv)
      end

      protected

      # It allows to add a middleware block that is called during the parsing phase.
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

      # The options indexed by the short and the name (so doubled up in the hash).
      # @param with_implicit [Boolean] whether free implicit shorts of declared options should be included
      #   among the keys (pointing to the specific option that has it implicit).
      def options_hash(with_implicit: false)
        @options_hash ||= {}
        return @options_hash unless with_implicit
        @options_hash.merge(implicit_shorts)
      end

      # This covers the gap where `OptionParser` auto-generates shorts out of option names.
      # @note `OptionParser` implicitly generates a short for the option name. When defining
      #   an option that uses this short, the short gets overriden/reused by the explicit option.
      #   Otherwise, the short is actually available for the former option, regarldess you
      #   specified a different short for it (i.e. both shorts, expicit and implicit, will work).
      # @note for two options with same implicit free short, latest in order will take it, which
      #   is what `OptionParser` will actually do.
      # @return [Hash] with free shorts that are implicit to some option
      def implicit_shorts
        options.each_with_object({}) do |opt, implicit|
          short = opt.short_implicit
          implicit[short] = opt unless options_hash.key?(short)
        end
      end

      private

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
      # @todo allow to specif if `:tail`, `:top` or `:base` (default)
      # @return [Boolean] wheter or not it succeeded adding the option.
      def add_to_options(opt, override: true)
        if sprev = options_hash[opt.short]
          return false unless override
          puts "Warning: Overriding option '#{sprev.name}' with short '#{sprev.short}' ('#{opt.name}')"
          delete_from_options(sprev)
        end
        if nprev = options_hash[opt.name]
          return false unless override
          puts "Warning: Overriding option '#{nprev.short}' with name '#{nprev.name}' ('#{opt.short}')"
          delete_from_options(nprev)
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
  end
end

require_relative 'options/set'
