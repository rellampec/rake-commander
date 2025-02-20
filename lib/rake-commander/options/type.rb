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
          correct = ALLOWED_TYPES.any? do |allowed|
            arg.is_a?(allowed)
          end

          args.delete(type) if correct

          correct
        end.first
      end
    end
  end
end
