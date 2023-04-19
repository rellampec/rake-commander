class RakeCommander
  module Options
    module Name
      # Substitions
      HYPHEN_START_REGEX  = /^-+/.freeze
      HYPEN_REGEX         = /-+/.freeze
      UNDERSCORE_REGEX    = /_+/.freeze
      SPACE_REGEX         = /\s+/.freeze
      # Checkers
      OPTIONAL_REGEX      = /\[\w+\]$/.freeze
      SINGLE_HYPHEN_REGEX = /^-(?<options>[^- ][^ ]*)/.freeze
      DOUBLE_HYPHEN_REGEX = /^--(?<option>[^- ][^ ]*)/.freeze

      # @return [Boolean]
      def single_hyphen?(value)
        return false unless value.respond_to?(:to_s)
        !!value.to_s.match(SINGLE_HYPHEN_REGEX)
      end

      # @return [Boolean]
      def double_hyphen?(value)
        return false unless value.respond_to?(:to_s)
        !!value.to_s.match(DOUBLE_HYPHEN_REGEX)
      end

      # @param strict [Boolean] whether hyphen is required when declaring an option `short`
      # @return [Boolean]
      def valid_short?(value, strict: false)
        return false unless value.respond_to?(:to_s) && !value.to_s.empty?
        return false unless !strict || single_hypen(value)
        short_sym(value).to_s.length == 1
      end

      # @param strict [Boolean] whether hyphen is required when declaring an option `name`
      # @return [Boolean]
      def valid_name?(value, strict: false)
        return false unless value.respond_to?(:to_s) && !value.to_s.empty?
        return false unless !strict || double_hyphen?(value)
        name_sym(value).to_s.length > 1
      end

      # @param strict [Boolean] whether hyphen is required when declaring an option `short`
      # @return [Boolean] whether `value` is an hyphened option `short`
      def short_hyphen?(value, strict: false)
        short?(value, strict: strict) && single_hypen(value)
      end

      # @param strict [Boolean] whether hyphen is required when declaring an option `name`
      # @return [Boolean] whether `value` is an hyphened option `name`
      def name_hyphen?(value, strict: false)
        name?(value, strict: strict) && double_hyphen?(value)
      end

      # Converter
      # @example
      #   * `"-d"` becomes `:d`
      # @return [Symbol, NilClass]
      def short_sym(value)
        return nil unless value
        value = value.to_s.gsub(HYPHEN_START_REGEX, '')
        return nil unless value = value.chars.first
        value.to_sym
      end

      # Converter.
      # @example
      #   * `"--there-we-go   ARGUMENT"` becomes `:"there_we_go ARGUMENT"`
      # @note
      #   1. It removes the double hyphen start (`--`)
      #   2. Replaces any intermediate hyphen by underscore `_`
      #   3. Replaces any multi-spacing by single space ` `
      # @return [Symbol, NilClass]
      def name_sym(value)
        return nil unless value
        value = value.to_s.gsub(HYPHEN_START_REGEX, '')
        value = value.gsub(HYPEN_REGEX, '_')
        value = value.gsub(SPACE_REGEX, ' ')
        return nil if value.empty?
        value.to_sym
      end

      # It's like `#name_sym` but it only gets the option name.
      # @example
      #   * `"--there-we-go   ARGUMENT"` becomes `:there_we_go`
      # @see #name_sym
      # @return [Symbol, NilClass]
      def name_word_sym(value)
        return nil unless value = name_sym(value)
        return nil unless value = name_words(value).first
        value.to_sym
      end

      # @return [String, NilClass] it returns the hyphened (`-`) version of a short `value`
      def short_hyphen(value)
        return nil unless value = short_sym(value)
        "-#{value}"
      end

      # Gets the actual name of the option. First word.
      # @example
      #   * `"--there-we-go   ARGUMENT"` becomes `"--there-we-go"`
      #   * `"there-we-go"` becomes `"--there-we-go"`
      #   * `:there_we_go` becomes `"--there-we-go"`
      # @return [String, NilClass] option `name` alone double hypened (`--`)
      def name_hyphen(value)
        return nil unless value = name_sym(value)
        value = value.to_s.gsub(UNDERSCORE_REGEX, '-')
        return nil if value.empty?
        "--#{value}"
      end

      # @example
      #   * `"--there-we-go   ARGUMENT"` returns `"ARGUMENT"`
      # @return [String, NilClass] the argument of `value`, if present
      def name_argument(value)
        name_words(value)[1]
      end

      # @example
      #   * `"--there-we-go   ARGUMENT"` returns `true`
      #   * `"--time"` returns `false`
      # @return [String, NilClass] whether `value` is a name with argument
      def name_argument?(value)
        !!name_argument(value)
      end

      # @example
      #   * `"--there-we-go   [ARGUMENT]"` returns `false`
      #   * `"--folder  FOLDER"` returns `true`
      #   * `"--time"` returns `false`
      # @return [Boolean] `true` if `value` does NOT end with `[String]`
      def argument_required?(value)
        return false unless value
        !argument_optional?(value)
      end

      # @example
      #   * `"--there-we-go   [ARGUMENT]"` returns `true`
      #   * `"--folder  FOLDER"` returns `false`
      #   * `"--time"` returns `true`
      # @note when there is NO argument it evaluates `true`
      # @return [Boolean] `true` if `value` ends with `[String]`
      def argument_optional?(value)
        return true unless value
        !!value.match(OPTIONAL_REGEX)
      end

      private

      # @example
      #   * `"--there-we-go   [ARGUMENT]"` returns `["there-we-go","[ARGUMENT]"]`
      # @return [Array<String>] the words of `value` without hyphen start
      def name_words(value)
        return nil unless value
        value = value.to_s.gsub(HYPHEN_START_REGEX, '')
        value.to_s.split(SPACE_REGEX)
      end
    end
  end
end
