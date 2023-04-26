class RakeCommander
  module Options
    module Error
      # Relates to the `required` parameter when defining an option.
      class MissingOption < RakeCommander::Options::Error::Base
        def initialize(value = nil, from: nil)
          super("missing required option: #{to_message(value)}", from: from)
        end

        def options
          super | to_options(@value)
        end

        protected

        def to_message(value)
          case value
          when RakeCommander::Option
            "#{value.name_hyphen} (#{value.short_hyphen})"
          when Hash
            to_message(value.values.uniq)
          when Array
            value.map do |v|
              v.is_a?(RakeCommander::Option)? to_message(v) : v
            end.join(', ')
          else
            super
          end
        end

        private

        def to_options(value)
          case value
          when RakeCommander::Option
            [value]
          when Array
            value.select {|v| v.is_a?(RakeCommander::Option)}
          when Hash
            to_options(value.values)
          else
            []
          end.compact
        end
      end
    end
  end
end
