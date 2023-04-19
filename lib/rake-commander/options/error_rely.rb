class RakeCommander
  module Options
    # Relies between OptionParser and RakeCommander errors
    class ErrorRely < StandardError
      extend RakeCommander::Options::Name

      OPTION_REGEX = /(?:argument|option): (?<option>.+)/i.freeze

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
        return @option_sym if @option_sym
        return nil unless match = message.match(self.class::OPTION_REGEX)
        option = match[:option]
        @option_sym = \
          if option.length > 1
            self.class.name_word_sym(option)
          else
            self.class.short_sym(option)
          end
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
