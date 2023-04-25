class RakeCommander
  module Options
    module Name
      BOOLEAN_TOKEN       = '[no-]'.freeze
      # Substitions
      HYPHEN_START_REGEX  = /^-+/.freeze
      HYPEN_REGEX         = /-+/.freeze
      UNDERSCORE_REGEX    = /_+/.freeze
      WORD_DELIMITER      = /[\s=]+/.freeze
      # Checkers / Capturers
      OPTIONAL_REGEX      = /\[\w+\]$/.freeze
      SINGLE_HYPHEN_REGEX = /^-(?<options>[^- ][^ ]*)/.freeze
      DOUBLE_HYPHEN_REGEX = /^(?:--\[?no-\]?|--)(?<option>[^- ][^ \r\n]*).*$/.freeze
      BOOLEAN_NAME_REGEX  = /^[^ ]*#{Regexp.escape(BOOLEAN_TOKEN)}[^ ]{2,}/.freeze

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

      # @return [Boolean] whether the name has the boolean switch `[no-]`
      def boolean_name?(value)
        return false unless value.respond_to?(:to_s)
        !!value.to_s.match(BOOLEAN_NAME_REGEX)
      end

      # @param strict [Boolean] whether hyphen is required when declaring an option `short`
      # @return [Boolean]
      def valid_short?(value, strict: false)
        return false unless value.respond_to?(:to_s)
        value = value.to_s.strip
        return false if value.empty?
        return false if strict && !single_hyphen?(value)
        value = value.gsub(HYPHEN_START_REGEX, '')
        value.length == 1
      end

      # @param strict [Boolean] whether hyphen is required when declaring an option `name`
      # @return [Boolean]
      def valid_name?(value, strict: false)
        return false unless value.respond_to?(:to_s)
        value = value.to_s.strip
        return false if value.empty?
        return false if strict && !double_hyphen?(value)
        name_sym(value).to_s.length > 1
      end

      # Modifies `args` and returns the short candidate
      # @param args [Array<String, Symbol>]
      # @return [String, Symbol] the short candidate
      def capture_arguments_short!(args, strict: true, symbol: false)
        capture_argument_with!(args) do |arg|
          next false unless arg.is_a?(String) || arg.is_a?(Symbol)
          next false if symbol && !arg.is_a?(Symbol)
          valid_short?(arg, strict: strict)
        end
      end

      # Modifies `args` and returns the name candidate
      # @param args [Array<String, Symbol>]
      # @return [String, Symbol] the name candidate
      def capture_arguments_name!(args, strict: true, symbol: false)
        capture_argument_with!(args) do |arg|
          next false unless arg.is_a?(String) || arg.is_a?(Symbol)
          next false if symbol && !arg.is_a?(Symbol)
          valid_name?(arg, strict: strict)
        end
      end

      # Modifies `args` and returns the arg candidate
      # @param args [Array<String, Symbol>]
      # @return [String, Symbol, NilClass] the arg candidate
      def capture_argument_with!(args)
        raise ArgumentError, "Expecting Array. Given: #{args.class}" unless args.is_a?(Array)
        args.dup.find.with_index do |arg, i|
          yield(arg).tap do |valid|
            next unless valid
            args.delete(i)
            return arg
          end
        end
        nil
      end

      # Converter
      # @example
      #   * `"-d"` becomes `:d`
      # @return [Symbol, NilClass]
      def short_sym(value)
        return nil unless value
        value = value.to_s.gsub(BOOLEAN_TOKEN, '')
        value = value.gsub(HYPHEN_START_REGEX, '')
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
        value = value.gsub(WORD_DELIMITER, ' ')
        return nil if value.empty?
        value.to_sym
      end

      # It's like `#name_sym` but it only gets the option name.
      # @note
      #   1. It also removes the boolean token `[no-]`
      # @example
      #   * `"--there-we-go   ARGUMENT"` becomes `:there_we_go`
      #   * `"--[no]-verbose"` becomes `:verbose`
      # @see #name_sym
      # @return [Symbol, NilClass]
      def name_word_sym(value)
        return nil unless value = name_sym(value)
        value = value.to_s.gsub(BOOLEAN_TOKEN, '')

        return nil unless value = name_words(value).first
        value.downcase.to_sym
      end

      # @return [String, NilClass] it returns the hyphened (`-`) version of a short `value`
      def short_hyphen(value)
        return nil unless value = short_sym(value)
        "-#{value}"
      end

      # Gets the actual name of the option. First word.
      # @example
      #   * `"--there-we-go   ARGUMENT"` becomes `"--there-we-go ARGUMENT"`
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
        value.to_s.split(WORD_DELIMITER)
      end
    end
  end
end
