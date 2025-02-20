class RakeCommander
  module Base
    # This class allows to use both method calls to `raise` by using additional parameters.
    # @note Although not clearly explained, this is somehow captured here https://stackoverflow.com/a/32481520/4352306
    class CustomError < StandardError
      def initialize(value = nil)
        super(@message = to_message(value)) if @value = value
      end

      # If @value was already set, ignore the latest message and
      # just return @message
      def to_s
        return @message if @message

        unclassed(super)
      end

      # If @value was already set, ignore the latest message
      # just return @message
      def message
        return @message if @message

        to_message(unclassed(super))
      end

      protected

      # Any **children classes** that want to extend how `value` is transformed
      # into a `message` **should extend this method**.
      # @return [String] `message`
      def to_message(value)
        case value
        when StandardError
          to_message(value.message)
        when String, NilClass
          value
        else
          raise ArgumentError, "Expecting String, StandardError or NilClass. Given: #{value.class}"
        end
      end

      private

      # When `value` is `nil` **methods** `to_s` and `message` return the error class of `self`.
      # This helper allows to remove that part to know if the error was raised with `nil`
      # @return [String]
      def unclassed(str)
        str.to_s.gsub(self.class.to_s, '').strip
      end
    end
  end
end
