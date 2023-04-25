class RakeCommander
  module Options
    module Error
      # Base error class that does a rely between OptionParser and RakeCommander errors
      class Base < StandardError
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

        attr_reader :from

        def initialize(value = nil, from: nil)
          @value   = value
          @from    = from
          return unless value?
          @message = to_message(value)
          super(@message)
        end

        def value?
          @value
        end

        def to_s
          return @message if value?
          unclassed(super)
        end

        def message
          return @message if value?
          to_message(unclassed(super))
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

        private

        def unclassed(str)
          str.to_s.gsub(self.class.to_s, '').strip
        end

        def to_message(value)
          case value
          when StandardError
            "#{from_desc}#{value.message}"
          when Array
            to_message(value.map {|v| "'#{v}'"}.join(', '))
          when String
            "#{from_desc}#{value}"
          when NilClass
            value
          else
            raise ArgumentError, "Expecting String or OptionParser error. Given: #{value.class}"
          end
        end
      end
    end
  end
end
