class RakeCommander
  module Options
    module Description
      DESC_MAX_LENGTH = 80

      private

      def fetch_desc!(args)
        descs = args.dup.select do |arg|
          arg.is_a?(String).tap do |is_string|
            next unless is_string

            args.delete(arg)
          end
        end.uniq

        joined_lines(*descs)
      end

      def string_to_lines(str, max: DESC_MAX_LENGTH)
        str.scan(liner_regex(max)).map(&:strip)
      end

      def liner_regex(len = DESC_MAX_LENGTH)
        /[^\n\r]{0,#{len}}[^ ](?:\s|$)/mi
      end

      def joined_lines(*lines, join: "\n")
        lines = lines.compact.map(&:strip).reject(&:empty?)
        return unless lines.count.positive?

        first = lines.first
        first = "#{first}." unless first.end_with?('.')

        (lines[1..] || []).reduce(first) do |mem, line|
          mem = "#{mem}."   unless mem.end_with?('.')
          line = "#{line}." unless line.end_with?('.')

          "#{mem}#{join}#{line}"
        end
      end
    end
  end
end
