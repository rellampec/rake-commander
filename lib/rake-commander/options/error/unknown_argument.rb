class RakeCommander
  module Options
    module Error
      # Relates to `OptionParser#parse` output (**leftovers**)
      class UnknownArgument < StandardError
        def initialize(value)
          super(to_message(value))
        end

        private

        def to_message(value)
          case value
          when Array
            to_message(value.map {|v| "'#{v}'"}.join(', '))
          else
            "These are unknown options: #{value}"
          end
        end
      end
    end
  end
end
