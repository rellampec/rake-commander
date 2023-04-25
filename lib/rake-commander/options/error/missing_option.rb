class RakeCommander
  module Options
    module Error
      # Relates to the `required` parameter when defining an option.
      class MissingOption < RakeCommander::Options::Error::Base
        def initialize(value = nil, from: nil)
          super("missing required option: #{to_message(value)}", from: from)
        end

        private

        def to_message(value)
          case value
          when RakeCommander::Option
            "#{value.name_hyphen} (#{value.short_hyphen})"
          when Hash
            to_message(value.values.uniq)
          when Array
            value.map do |v|
              to_message(v)
            end.join(', ')
          else
            super
          end
        end
      end
    end
  end
end
