class RakeCommander
  module Options
    module Name
      HYPPHEN_START_REGEX = /^(-+)/.freeze
      HYPEN_REGEX         = /(-+)/.freeze
      UNDERSCORE_REGEX    = /(_+)/.freeze

      def short_sym(value)
        return nil unless value
        value = value.to_s.gsub(HYPPHEN_START_REGEX, '')
        return nil unless value = value.chars.first
        value.to_sym
      end

      def short_hyphen(value)
        return nil unless value = short_sym(value)
        "-#{value}"
      end

      def name_sym(value)
        return nil unless value
        value = value.to_s.gsub(HYPPHEN_START_REGEX, '')
        value = value.gsub(HYPEN_REGEX, '_')
        return nil if value.empty?
        value.to_sym
      end

      def name_hyphen(value)
        return nil unless value = name_sym(value)
        value = value.to_s.gsub(UNDERSCORE_REGEX, '-')
        return nil if value.empty?
        "--#{value}"
      end
    end
  end
end
