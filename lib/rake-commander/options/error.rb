require_relative 'error/base'
require_relative 'error/missing_argument'
require_relative 'error/invalid_argument'
require_relative 'error/invalid_option'
require_relative 'error/missing_option'
require_relative 'error/unknown_argument'


class RakeCommander
  module Options
    module Error
      class << self
        def included(base)
          super(base)
          base.extend ClassMethods
          base.attr_inheritable :error_on_leftovers, :leftovers_callback
        end
      end

      module ClassMethods
        # Whether it should trigger an error when there are argument leftovers
        # after parsing `ARGV`.
        # @note
        #   1. It triggers error by default when there are parsing `leftovers`.
        #   2. Even if a block is defined, if action is `false` it won't trigger error.
        # @raise [RakeCommander::Options::UnknownArgument]
        #   1. when `action` is `true` (default)
        #   2. when the `action_block` is defined and returns `true`.
        # @yield [leftovers, results] do something with leftovers and parsed options.
        #   * The block is only called if there are `leftovers`.
        # @yieldparam leftovers [Array<String>] the leftovers.
        # @yieldparam results [Hash] the parsed options.
        # @yieldreturn [Boolean] whether this should trigger an error or not.
        # @return [Boolean] whether this error is enabled.
        def error_on_leftovers(action = :not_used, &block)
          @error_on_leftovers = action if action != :not_used
          if block_given?
            @leftovers_callback = block
            @error_on_leftovers = true
          end
          return self unless block_given? || action != :not_used
          @error_on_leftovers = true unless @error_on_leftovers == false
          @error_on_leftovers
        end

        # Re-open method to add all the error handling.
        # @see RakeCommander::Options::Result
        def parse_options(argv = ARGV, results: {}, leftovers: [], &block)
          super.tap do |_|
            manage_leftovers(leftovers, results)
            check_required_presence(results)
          end
        rescue OptionParser::InvalidOption => e
          eklass = RakeCommander::Options::Error::InvalidOption
          raise eklass.new(e, from: self), nil, cause: nil
        rescue OptionParser::MissingArgument => e
          eklass = RakeCommander::Options::Error::MissingArgument
          opt    = error_option(e, eklass)
          msg    = opt ? "missing required argument: #{opt.name_hyphen} (#{opt.short_hyphen})" : e.message
          raise eklass.new(from: self), msg, cause: nil
        rescue OptionParser::InvalidArgument => e
          eklass = RakeCommander::Options::Error::InvalidArgument
          opt    = error_option(e, eklass)
          raise eklass.new(e, from: self), nil, cause: nil unless opt&.argument_required?
          eklass = RakeCommander::Options::Error::MissingArgument
          msg = "missing required argument in option: #{opt.name_hyphen} (#{opt.short_hyphen})"
          raise eklass.new(from: self), msg, cause: nil
        end

        protected

        # Helper to retrieve an existing `RakeCommander::Option` out of a
        # `OptionParser` error.
        # @param e [OptionParser:Error] containing the original error `message`
        # @param eklass [RakeCommander::Options::Error:Base::Class] the error class to retrive the option key
        # @return [RakeCommander::Option, NilClass]
        def error_option(err, eklass)
          return false unless option_sym = eklass.option_sym(err.message)
          options_hash(with_implicit: true)[option_sym]
        end

        private

        # It implements the logic defined by `error_on_leftovers`.
        # @param leftovers [Array<String>]
        # @param results [Hash] the parsed options
        # @return [Hash] the results (same object)
        def manage_leftovers(leftovers, results)
          results.tap do |_r|
            next if leftovers.empty? || !error_on_leftovers
            eklass = RakeCommander::Options::Error::UnknownArgument
            raise eklass.new(leftovers, from: self) unless block = @leftovers_callback
            raise eklass.new(leftovers, from: self) if     block.call(leftovers, results)
          end
        end

        # It throws an exception if any of the required options
        # is missing in results
        def check_required_presence(results)
          missing = options.select(&:required?).reject do |opt|
            results.key?(opt.short) || results.key?(opt.name)
          end
          raise RakeCommander::Options::Error::MissingOption.new(missing, from: self) unless missing.empty?
        end
      end
    end
  end
end
