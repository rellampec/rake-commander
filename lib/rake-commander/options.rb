require_relative 'options/name'
require_relative 'options/description'
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
        base.extend RakeCommander::Base::ClassInheritable
        base.extend ClassMethods
        base.attr_inheritable :banner, :options_hash
        base.class_resolver :option_class, RakeCommander::Option
        base.send :include, RakeCommander::Options::Result
        base.send :include, RakeCommander::Options::Error
        base.send :include, RakeCommander::Options::Arguments
      end
    end

    module ClassMethods
      # Overrides the auto-generated banner
      def banner(desc = :not_used)
        return @banner = desc unless desc == :not_used
        return @banner if @banner
        return task_options_banner if respond_to?(:task_options_banner, true)
      end

      # Defines a new option or opens for edition an existing one if `reopen: true` is used.
      # @note
      #   - If override is `true`, it will with a Warning when same `short` or `name` clashes.
      def option(*args, override: true, reopen: false, **kargs, &block)
        return option_reopen(*args, override: override, **kargs, &block) if reopen
        opt = option_class.new(*args, **kargs, &block)
        add_to_options(opt, override: override)
      end

      # It re-opens an option for edition. If it does not exist, it **upserts** it.
      # @note
      #   1. If `override` is `false, it will fail to change the `name` or the `short`
      #     when they are already taken by some other option.
      #   2. It will have the effect of overriding existing options
      # @note when `short` and `name` are provided, `name` takes precedence over `short`
      #   in the lookup (to identify the existing option)
      def option_reopen(*args, override: false, **kargs, &block)
        aux = option_class.new(*args, **kargs, sample: true, &block)
        opt = options_hash.values_at(aux.name, aux.short).compact.first
        return option(*args, **kargs, &block) unless opt
        replace_in_options(opt, opt.merge(aux), override: override)
      end

      # Removes options with short or name `keys` from options
      def option_remove(*keys)
        keys.map do |key|
          aux = option_class.new(key, sample: true)
          opt = options_hash.values_at(aux.name, aux.short).compact.first
          delete_from_options(opt) if opt
        end
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

      # It builds the `OptionParser` injecting the `middleware` block and parses `argv`
      # @note this method is extended in via the following modules:
      #   1. `RakeCommander::Options::Result`: makes the method to return a `Hash` with results,
      #     as well as captures/moves the **leftovers** to their own keyed argument.
      #   2. `RakeCommander::Options:Error`: adds error handling (i.e. forward to rake commander errors)
      # @param argv [Array<String>] the command line arguments to be parsed.
      # @return [Array<String>] the **leftovers** of the `OptionParser#parse` call.
      def parse_options(argv = ARGV, &middleware)
        options_parser(&middleware).parse(argv)
      end

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

      protected

      # It allows to add a middleware block that is called during the parsing phase.
      # @return [OptionParser] the built options parser.
      def options_parser(&middleware)
        new_options_parser do |opts|
          opts.banner = banner if banner
          option_help(opts)
          free_shorts = implicit_shorts

          options.each do |opt|
            free_short = free_shorts.key?(opt.short_implicit)
            opt.add_switch(opts, implicit_short: free_short, &middleware)
          end
        end
      end

      # @return [OptionParser]
      def new_options_parser(&block)
        require 'optparse'
        OptionParser.new(&block)
      end

      # The options indexed by the short and the name (so doubled up in the hash).
      # @param with_implicit [Boolean] whether free implicit shorts of declared options should be included
      #   among the keys (pointing to the specific option that has it implicit).
      # @return [Hash] with Symbol name and shorts as keys, and `RakeCommander::Option` as values.
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

      # Explicitly installs the help of the options
      # @note `OptionParser` already has `-h --help` as a native option.
      # @param opts [OptionParser] where the help will be added.
      def option_help(opts)
        return false if options_hash.key?(:help) || options_hash.key?(:h)
        option(:h, :help, 'Prints this help') do
          puts opts
          exit(0)
        end
        self
      end

      # @todo check that all the elements are of `option_class`
      # @return [Array<RakeCommander::Option>]
      def to_options(opts)
        if opts.is_a?(Hash)
          opts.values
        elsif opts.is_a?(RakeCommander::Options::Set)
          opts.class.options
        elsif opts <= RakeCommander::Options::Set
          opts.options
        elsif opts.respond_to?(:to_a)
          opts.to_a
        end
      end

      # Adds to `@options_hash` the option `opt`
      # @todo add `exception` parameter, to trigger an exception
      #   when `opt` name or short are taken (and override is `false`)
      # @todo allow to specif if `:tail`, `:top` or `:base` (default)
      # @param opt [RakeCommander::Option] the option to be added.
      # @param override [Boolean] whether we should continue, may this action override (an)other option(s).
      # @return [RakeCommander::Option, NilClass] the option that was added, `nil` is returned otherwise.
      def add_to_options(opt, override: true)
        name_ref = respond_to?(:name)? " (#{name})" : ''
        if sprev = options_hash[opt.short]
          return nil unless override
          puts "Warning#{name_ref}: Overriding option '#{sprev.name}' with short '#{sprev.short}' ('#{opt.name}')"
          delete_from_options(sprev)
        end
        if nprev = options_hash[opt.name]
          return nil unless override
          puts "Warning#{name_ref}: Overriding option '#{nprev.short}' with name '#{nprev.name}' ('#{opt.short}')"
          delete_from_options(nprev)
        end
        options_hash[opt.name] = options_hash[opt.short] = opt
      end

      # Deletes an option from the `options_hash`
      # @param opt [RakeCommander::Option] the option to be deleted.
      # @return [RakeCommander::Option, NilClass] the option that was deleted, or `nil` otherwise.
      def delete_from_options(opt)
        res = options_hash.delete(opt.short)
        options_hash.delete(opt.name) || res
      end

      # Replaces option `ref` with option `opt`.
      # @note this method was added aiming to keep the same position for an option we override.
      # @param ref [RakeCommander::Option] the option to be replaced.
      # @param opt [RakeCommander::Option] the option that will replace `ref`.
      # @param override [Boolean] whether we should continue, may there be collateral override to other options.
      # @return [RakeCommander::Option, NilClass] `opt` if it was added, or `nil` otherwise.
      def replace_in_options(ref, opt, override: false)
        # Try to keep the same potition
        options_hash[ref.short] = options_hash[ref.name] = nil
        add_to_options(opt, override: override).tap do |added_opt|
          # restore previous status
          next options_hash[ref.short] = options_hash[ref.name] = ref unless added_opt
          delete_empty_keys(options_hash)
        end
      end

      # Deletes all keys that have `nil` as value
      def delete_empty_keys(hash)
        hash.tap do |_h|
          hash.dup.each do |k, v|
            next unless v.nil?
            hash.delete(k)
          end
        end
      end
    end
  end
end

require_relative 'options/set'
