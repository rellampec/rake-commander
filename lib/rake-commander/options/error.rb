require_relative 'error/base'
require_relative 'error/missing_argument'
require_relative 'error/invalid_argument'
require_relative 'error/invalid_option'
require_relative 'error/missing_option'
require_relative 'error/unknown_argument'
require_relative 'error/handling'

class RakeCommander
  module Options
    module Error
      class << self
        def included(base)
          super
          base.send :include, RakeCommander::Options::Error::Handling
          base.extend ClassMethods
        end
      end

      module ClassMethods
        # Re-open method to add all the error handling.
        # @see RakeCommander::Options::Result
        def parse_options(argv = ARGV, results: {}, leftovers: [], &block)
          with_error_handling(argv, results, leftovers) do
            super.tap do
              check_on_leftovers(leftovers)
              check_required_presence(results)
            end
          rescue OptionParser::InvalidOption => e
            eklass = RakeCommander::Options::Error::InvalidOption
            raise eklass.new(e, from: self), nil, cause: nil
          rescue OptionParser::MissingArgument => e
            eklass = RakeCommander::Options::Error::MissingArgument
            opt    = error_option(e, eklass)
            msg    = e.message
            msg    = "missing required argument: #{opt.name_hyphen} (#{opt.short_hyphen})" if opt
            raise eklass.new(from: self, option: opt), msg, cause: nil
          rescue OptionParser::InvalidArgument => e
            eklass = RakeCommander::Options::Error::InvalidArgument
            src_e  = nil
            msg    = nil
            opt    = error_option(e, eklass)

            if opt&.enum?
              msg  = "argument in option #{opt.name_hyphen} (#{opt.short_hyphen}) "
              msg << "should be any of [#{opt.enum_options.join(' | ')}]"
            elsif opt&.argument_required?
              eklass = RakeCommander::Options::Error::MissingArgument
              msg    = "missing required argument in option: #{opt.name_hyphen} (#{opt.short_hyphen})"
            else
              src_e  = e
            end

            raise eklass.new(src_e, from: self, option: opt), msg, cause: nil
          end
        end

        protected

        # Helper to retrieve an existing `RakeCommander::Option` out of a
        # `OptionParser` error.
        # @param e [OptionParser:Error] containing the original error `message`
        # @param eklass [RakeCommander::Options::Error:Base::Class] the error class to retrive the option key
        # @return [RakeCommander::Option, NilClass]
        def error_option(err, eklass)
          return false unless (option_sym = eklass.option_sym(err.message))

          options_hash(with_implicit: true)[option_sym]
        end

        private

        # It implements the logic defined by `error_on_leftovers`.
        # @param leftovers [Array<String>]
        # @param results [Hash] the parsed options
        # @return [Hash] the results (same object)
        def check_on_leftovers(leftovers)
          return if leftovers.empty?

          eklass = RakeCommander::Options::Error::UnknownArgument
          raise eklass.new(leftovers, from: self)
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
