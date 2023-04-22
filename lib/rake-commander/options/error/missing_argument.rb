class RakeCommander
  module Options
    module Error
      # Relates to options with missing required argument (when there's no `default` value) 
      class MissingArgument < RakeCommander::Options::Error::Rely
        option_regex /missing(?: required|) argument: (?<option>.+)/i.freeze
      end
    end
  end
end
