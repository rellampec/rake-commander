class RakeCommander
  module Options
    module Error
      # @note Although a more proper name would be `InvalidOption`, the invalid
      #   argument is not an actual option. Name was kept for naming consistency
      #   with `OptionParser::InvalidArgument`
      class InvalidArgument < RakeCommander::Options::Error::Rely
        option_regex(/invalid argument: (?<option>.+)/i.freeze)
      end
    end
  end
end
