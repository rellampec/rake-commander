class RakeCommander
  module Options
    module Description
      DESC_MAX_LENGTH = 80

      private

      def string_to_lines(str, max: DESC_MAX_LENGTH)
        str.scan(liner_regex(max)).map(&:strip)
      end

      def liner_regex(len = DESC_MAX_LENGTH)
        /.{0,#{len}}[^ ](?:\s|$)/mi
      end
    end
  end
end
