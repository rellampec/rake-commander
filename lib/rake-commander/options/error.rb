require_relative 'error_rely'
class RakeCommander
  module Options
    class MissingOption < RakeCommander::Options::ErrorRely
      def initialize(value)
        super("missing required option: #{to_description(value)}")
      end
    end

    class MissingArgument < RakeCommander::Options::ErrorRely
      option_regex /missing(?: required|) argument: (?<option>.+)/i.freeze
    end

    class InvalidArgument < RakeCommander::Options::ErrorRely
      option_regex /invalid argument: (?<option>.+)/i.freeze
    end
  end
end
