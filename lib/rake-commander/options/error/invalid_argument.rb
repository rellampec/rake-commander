class RakeCommander
  module Options
    module Error
      class InvalidArgument < RakeCommander::Options::Error::Base
        option_regex(/invalid argument: (?<option>.+)/i.freeze)

        private

        def to_message(value)
          return super unless opt = option
          case value
          when OptionParser::InvalidArgument
            super("invalid option argument: #{opt.name_hyphen} (#{opt.short_hyphen})")
          else
            super
          end
        end
      end
    end
  end
end
