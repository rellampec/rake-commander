class RakeCommander
  module Options
    module Error
      class InvalidOption < RakeCommander::Options::Error::Base
        option_regex(/invalid option: (?<option>.+)/i.freeze)
      end
    end
  end
end
