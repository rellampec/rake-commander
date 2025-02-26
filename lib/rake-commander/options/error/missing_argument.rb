class RakeCommander
  module Options
    module Error
      # Relates to options with missing required argument (when there's no `default` value)
      class MissingArgument < RakeCommander::Options::Error::Base
        option_regex(/missing(?: required|) argument: (?<option>.+)/i)
      end
    end
  end
end
