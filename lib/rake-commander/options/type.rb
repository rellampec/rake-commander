class RakeCommander
  module Options
    module Type
      ALLOWED_TYPES = [
        Class,
        Array
      ].freeze

      private

      def fetch_type!(args)
        args.dup.select do |arg|
          allowed_type?(arg).tap do |is_type|
            next unless is_type

            args.delete(arg)
          end
        end.first
      end

      def allowed_type?(value)
        ALLOWED_TYPES.any? do |allowed|
          value.is_a?(allowed)
        end
      end
    end
  end
end
