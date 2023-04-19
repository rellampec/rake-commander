require_relative 'error_rely'
class RakeCommander
  module Options
    class MissingOption < RakeCommander::Options::ErrorRely
      def initialize(value)
        super("missing required option: #{to_description(value)}")
      end
    end

    class MissingArgument < RakeCommander::Options::ErrorRely
      OPTION_REGEX = /missing (?:required|) argument: (?<option>.+)/i.freeze
    end

    class InvalidArgument < RakeCommander::Options::ErrorRely
      OPTION_REGEX = /invalid argument: (?<option>.+)/i.freeze
    end
  end
end
