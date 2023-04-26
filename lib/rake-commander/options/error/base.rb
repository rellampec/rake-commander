class RakeCommander
  module Options
    module Error
      # Base error class that does a rely between OptionParser and RakeCommander errors
      class Base < RakeCommander::Base::CustomError
        extend RakeCommander::Options::Name
        OPTION_REGEX = /(?:argument|option): (?<option>.+)/i.freeze

        class << self
          # Helper to check if `error` is this class or any children class
          # @raise ArgumentError if it does not meet this condition.
          def require_argument!(error, arg_name, accept_children: true)
            msg  = "Expecting #{arg_name} to be #{self}"
            msg << "or child thereof." if accept_children
            msg << ". Given: #{error.is_a?(Class)? error : error.class}"
            raise ArgumentError, msg unless error <= self
          end

          # To (re)define the RegExp used to identify the option of an error message.
          def option_regex(value = :not_used)
            @option_regex ||= OPTION_REGEX
            return @option_regex if value == :not_used
            @option_regex = value
          end

          # Identifies the option `Symbol` (short or name) for a given message
          def option_sym(message)
            return nil unless match = message.match(option_regex)
            option = match[:option]
            return name_word_sym(option) if option.length > 1
            short_sym(option)
          end
        end

        attr_reader :from, :option

        def initialize(value = nil, from: nil, option: nil)
          @from   = from
          @option = option
          super(value)
        end

        # Options that are related to the error. There may not be any.
        def options
          [option].compact.flatten
        end

        def name?
          option_sym.to_s.length > 1
        end

        def short?
          option_sym.to_s.length == 1
        end

        def option_sym
          @option_sym ||= self.class.option_sym(message)
        end

        def from_desc
          return '' unless from
          if from.respond_to?(:name)
            "(#{from.name}) "
          elsif from.respond_to?(:to_s)
            "(#{from}) "
          else
            ''
          end
        end

        protected

        def to_message(value)
          case value
          when Array
            to_message(value.map {|v| "'#{v}'"}.join(', '))
          when String
            "#{from_desc}#{super}"
          else
            super
          end
        end
      end
    end
  end
end
