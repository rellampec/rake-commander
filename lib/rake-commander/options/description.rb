class RakeCommander
  module Options
    module Description
      DESC_MAX_LENGTH = 80

      private

      def fetch_desc!(args)
        args.dup.select do |arg|
          next unless arg.is_a?(String)

          args.delete(arg)
          true
        end.compact.
          unique.
          map(&:strip).
          join("\n")
      end

      def string_to_lines(str, max: DESC_MAX_LENGTH)
        str.scan(liner_regex(max)).map(&:strip)
      end

      def liner_regex(len = DESC_MAX_LENGTH)
        /.{0,#{len}}[^ ](?:\s|$)/mi
      end
    end
  end
end
