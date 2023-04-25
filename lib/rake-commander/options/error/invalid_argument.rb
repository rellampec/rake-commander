class RakeCommander
  module Options
    module Error
      class InvalidArgument < RakeCommander::Options::Error::Base
        option_regex(/invalid argument: (?<option>.+)/i.freeze)
      end
    end
  end
end
