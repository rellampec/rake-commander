class RakeCommander
  module Options
    module Error
      # Relates to `OptionParser#parse` output (**leftovers**)
      class UnknownArgument < RakeCommander::Options::Error::Base
        def initialize(value = nil, from: nil)
          super("unknown arguments: #{to_message(value)}", from: from)
        end

        private

        def to_message(value)
          case value
          when Array
            value.map {|v| "'#{v}'"}.join(', ')
          else
            super
          end
        end
      end
    end
  end
end
