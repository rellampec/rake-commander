class RakeCommander
  @option_struct ||= Struct.new(:short, :name)
  class Option < @option_struct
    extend RakeCommander::Base::ClassHelpers
    extend RakeCommander::Options::Name
    include RakeCommander::Options::Description
    include RakeCommander::Options::Type

    attr_reader :name_full, :desc, :default

    # @param sample [Boolean] allows to skip the `short` and `name` validations
    def initialize(*args, sample: false, **kargs, &block)
      short, name = capture_arguments_short_n_name!(args, kargs, sample: sample)

      @name_full  = name.freeze
      super(short.freeze, @name_full)

      @default        = kargs[:default]  if kargs.key?(:default)
      @desc           = kargs[:desc]     if kargs.key?(:desc)
      @required       = kargs[:required] if kargs.key?(:required)
      @type_coercion  = kargs[:type]     if kargs.key?(:type)
      @other_args     = args
      @original_block = block

      configure_other
    end

    # Makes a copy of this option
    # @return [RakeCommander::Option]
    def dup(**kargs, &block)
      block ||= original_block
      self.class.new(**dup_key_arguments.merge(kargs), &block)
    end
    alias_method :deep_dup, :dup

    # Creates a new option, result of merging this `opt` with this option,
    # @return [RakeCommander::Option] where opt has been merged
    def merge(opt, **kargs)
      msg = "Expecting RakeCommander::Option. Given: #{opt.class}"
      raise msg unless opt.is_a?(RakeCommander::Option)

      dup(**opt.dup_key_arguments.merge(kargs), &opt.original_block)
    end

    # @return [Boolean] whether this option is required.
    def required?
      !!@required
    end

    # @return [Symbol]
    def short
      self.class.short_sym(super)
    end

    # `OptionParser` interprets free shorts that match the first letter of an option name
    # as an invocation of that option. This method allows to identify this.
    # return [Symbol]
    def short_implicit
      self.class.short_sym(@name_full)
    end

    # @return [String]
    def short_hyphen
      self.class.short_hyphen(short)
    end

    # @return [Symbol]
    def name
      self.class.name_word_sym(super)
    end

    # @return [String]
    def name_hyphen
      self.class.name_hyphen(name_full)
    end

    # @return [Boolean]
    def boolean_name?
      self.class.boolean_name?(name_full)
    end

    # @param [Boolean] whether this option allows an argument
    def argument?
      self.class.name_argument?(name_full)
    end

    # @param [String, Nil] the argument, may it exist
    def argument
      return unless argument?

      self.class.name_argument(name_full)
    end

    # @param [Boolean] If there was an argument, whether it is required
    def argument_required?
      self.class.argument_required?(argument)
    end

    # @return [Class, NilClass]
    def type_coercion
      value = @type_coercion || (default? && default.class)
      return unless allowed_type?(value)

      value
    end

    # @return [Boolean] whether the option is an enum with fixed values.
    def enum?
      type_coercion.is_a?(Array)
    end

    # @return [Array, NilClass] the valid options when is `enum?`
    def enum_options
      return unless enum?

      type_coercion
    end

    # @return [Boolean]
    def default?
      instance_variable_defined?(:@default)
    end

    # Adds this option's switch to the `OptionParser`
    # @note it allows to add a `middleware` block that will be called at `parse` runtime
    # @param opt_parser [OptionParser] the option parser to add this option's switch.
    # @param implicit_short [Boolean] whether the implicit short of this option is active in the opts_parser.
    def add_switch(opts_parser, where: :base, implicit_short: false, &middleware)
      msg = "Expecting OptionParser. Given: #{opts_parser.class}"
      raise msg unless opts_parser.is_a?(OptionParser)

      args  = switch_args(implicit_short: implicit_short)
      block = option_block(&middleware)

      case where
      when :head, :top
        opts_parser.on_head(*args, &block)
      when :tail, :end
        opts_parser.on_tail(*args, &block)
      else # :base
        opts_parser.on(*args, &block)
      end
      opts_parser
    end

    protected

    attr_reader :original_block

    # @return [Hash] keyed arguments to create a new object
    def dup_key_arguments
      {}.tap do |kargs|
        configure_other

        kargs.merge!(short:    short.dup.freeze)     if short
        kargs.merge!(name:     name_full.dup.freeze) if name_full
        kargs.merge!(desc:     @desc.dup)            if @desc
        kargs.merge!(default:  @default.dup)         if default?
        kargs.merge!(type:     dupped_type)          if allowed_type?(@type_coercion)
        kargs.merge!(required: required?)
      end
    end

    # @return [Array<Variant>]
    def switch_args(implicit_short: false)
      configure_other

      args = [short_hyphen, name_hyphen]
      args.push(*switch_desc(implicit_short: implicit_short))
      args << type_coercion if type_coercion
      args
    end

    private

    # Called on parse runtime
    def option_block(&middleware)
      block_extra_args = [default, short, name, self]

      proc do |value|
        value = !value if type_coercion == FalseClass
        args  = block_extra_args.dup.unshift(value)

        original_block&.call(*args)

        middleware&.call(*args)
      end
    end

    # @note in `OptionParser` you can multiline the description with alignment
    #   by providing multiple strings.
    # @return [Array<String>]
    def switch_desc(implicit_short: false, line_width: DESC_MAX_LENGTH)
      ishort = implicit_short ? "( -#{short_implicit} ) " : ''
      str    = "#{required_desc}#{ishort}#{desc}#{enum_desc}#{default_desc}"
      return [] if str.empty?

      string_to_lines(str, max: line_width)
    end

    def required_desc
      required?? "< REQ >  " : "[ opt ]  "
    end

    def default_desc
      return unless default?

      " { Default: '#{default}' }"
    end

    def enum_desc
      return unless enum?

      " Options: [ #{enum_options.join(' | ')} ]."
    end

    # Helper to simplify `short` and `name` capture from arguments and keyed arguments.
    # @return [Array<Symbol, String>] the pair `[short, name]`
    def capture_arguments_short_n_name!(args, kargs, sample: false)
      name, short = kargs.values_at(:name, :short)
      short ||= capture_arguments_short!(args)
      name  ||= capture_arguments_name!(args, sample_n_short: sample && short)

      unless sample
        msg = "A short of one letter should be provided. Given: #{short}"
        raise ArgumentError, msg unless self.class.valid_short?(short)

        msg = "A name should be provided. Given: #{name}"
        raise ArgumentError, msg unless self.class.valid_name?(name)
      end

      [short, name]
    end

    # Helper to figure out the option short from args
    # @note if found it removes it from args.
    # @return [String, Symbol, NilClass]
    def capture_arguments_short!(args)
      short = nil
      short ||= self.class.capture_arguments_short!(args, symbol: true)
      short ||= self.class.capture_arguments_short!(args, symbol: true, strict: false)
      short ||= self.class.capture_arguments_short!(args)
      short || self.class.capture_arguments_short!(args, strict: false)
    end

    # Helper to figure out the option name from args
    # @note if found it removes it from args.
    # @return [String, Symbol, NilClass]
    def capture_arguments_name!(args, sample_n_short: false)
      name   = nil
      name ||= self.class.capture_arguments_name!(args, symbol: true)
      name ||= self.class.capture_arguments_name!(args, symbol: true, strict: false)
      name ||= self.class.capture_arguments_name!(args)
      name ||= self.class.capture_arguments_name!(args, strict: false) unless sample_n_short
      name
    end

    # The remaining `args` received in the initialization
    def other_args(*args)
      @other_args ||= []
      return @other_args if args.empty?

      @other_args.push(*args)
    end

    # It consumes `other_args`, to prevent direct overrides to be overriden by it.
    # @note at the end we will pass the switch arguments to OptsParser.
    def configure_other
      @type_coercion = fetch_type_from_other(@type_coercion)
      @desc          = fetch_desc_from_other(@desc)
      nil
    end

    def fetch_type_from_other(original = nil)
      other_type = fetch_type!(other_args)

      return original if original

      other_type
    end

    def fetch_desc_from_other(original = nil)
      joined_lines(original, fetch_desc!(other_args))
    end

    def dupped_type
      return @type_coercion if @type_coercion.is_a?(Class)
      return @type_coercion unless @type_coercion.is_a?(Array)

      @type_coercion.map do |value|
        next value if value.is_a?(Class)
        next value unless value.respond_to?(:dup)

        value.dup
      end
    end
  end
end
