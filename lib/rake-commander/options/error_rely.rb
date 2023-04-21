class RakeCommander
  module Options
    # Relies between OptionParser and RakeCommander errors
    class ErrorRely < StandardError
      extend RakeCommander::Options::Name
      OPTION_REGEX = /(?:argument|option): (?<option>.+)/i.freeze

      class << self
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

      def initialize(value)
        case value
        when OptionParser::MissingArgument, OptionParser::InvalidArgument
          super(value.message)
        when String
          super(value)
        else
          raise ArgumentError, "Expecting String or OptionParser error. Given: #{value.class}"
        end
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

      private

      def to_description(value)
        case value
        when Hash
          to_description(value.values.uniq)
        when Array
          value.map do |v|
            to_description(v)
          end.join(', ')
        when RakeCommander::Option
          "#{value.name_hyphen} (#{value.short_hyphen})"
        else
          value
        end
      end
    end
  end
end
