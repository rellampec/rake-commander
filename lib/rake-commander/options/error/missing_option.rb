class RakeCommander
  module Options
    module Error
      # Relates to the `required` parameter when defining an option.
      class MissingOption < RakeCommander::Options::Error::Rely
        def initialize(value)
          super("missing required option: #{to_description(value)}")
        end
      end
    end
  end
end
