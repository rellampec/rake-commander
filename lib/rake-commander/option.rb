class RakeCommander
  @option_struct ||= Struct.new(:short, :name)
  class Option < @option_struct
    extend RakeCommander::Base::ClassHelpers
    extend RakeCommander::Options::Name
    include RakeCommander::Options::Description

    attr_reader :name_full, :desc, :default

    # @param sample [Boolean] allows to skip the `short` and `name` validations
    def initialize(*args, sample: false, **kargs, &block)
      short, name = capture_arguments_short_n_name!(args, kargs, sample: sample)
      @name_full  = name.freeze
      super(short.freeze, @name_full)
      @default        = kargs[:default]  if kargs.key?(:default)
      @desc           = kargs[:desc]     if kargs.key?(:desc)
      @required       = kargs[:required] if kargs.key?(:required)
      @type_coertion  = kargs[:type]     if kargs.key?(:type)
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
    def merge(opt)
      raise "Expecting RakeCommander::Option. Given: #{opt.class}" unless opt.is_a?(RakeCommander::Option)
      dup(**opt.dup_key_arguments, &opt.original_block)
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
      return nil unless argument?
      self.class.name_argument(name_full)
    end

    # @param [Boolean] If there was an argument, whether it is required
    def argument_required?
      self.class.argument_required?(argument)
    end

    # @return [Class, NilClass]
    def type_coertion
      @type_coertion || (default? && default.class)
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
      raise "Expecting OptionParser. Given: #{opts_parser.class}" unless opts_parser.is_a?(OptionParser)
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
        kargs.merge!(short:    short.dup.freeze)      if short
        kargs.merge!(name:     name_full.dup.freeze)  if name_full
        kargs.merge!(desc:     desc.dup)              if desc
        kargs.merge!(default:  default.dup)           if default?
        kargs.merge!(required: required?)
      end
    end

    # @return [Array<Variant>]
    def switch_args(implicit_short: false)
      configure_other
      args = [short_hyphen, name_hyphen]
      args.push(*switch_desc(implicit_short: implicit_short))
      args << type_coertion if type_coertion
      args
    end

    private

    # Called on parse runtime
    def option_block(&middleware)
      block_extra_args = [default, short, name]
      proc do |value|
        args = block_extra_args.dup.unshift(value)
        original_block&.call(*args)
        middleware&.call(*args)
      end
    end

    # @note in `OptionParser` you can multiline the description with alignment
    #   by providing multiple strings.
    # @return [Array<String>]
    def switch_desc(implicit_short: false, line_width: DESC_MAX_LENGTH)
      ishort = implicit_short ? "( -#{short_implicit} ) " : ''
      str    = "#{required_desc}#{ishort}#{desc}#{default_desc}"
      return [] if str.empty?
      string_to_lines(str, max: line_width)
    end

    def required_desc
      required?? "< REQ >  " : "[ opt ]  "
    end

    def default_desc
      return nil unless default?
      str = "{ Default: '#{default}' }"
      if desc && !desc.downcase.include?('default')
        str = desc.end_with?('.') ? " #{str}" : ". #{str}"
      end
      str
    end

    # Helper to simplify `short` and `name` capture from arguments and keyed arguments.
    # @return [Array<Symbol, String>] the pair `[short, name]`
    def capture_arguments_short_n_name!(args, kargs, sample: false)
      name, short = kargs.values_at(:name, :short)
      short ||= capture_arguments_short!(args)
      name  ||= capture_arguments_name!(args, sample_n_short: sample && short)

      unless sample
        raise ArgumentError, "A short of one letter should be provided. Given: #{short}" unless self.class.valid_short?(short)
        raise ArgumentError, "A name should be provided. Given: #{name}" unless  self.class.valid_name?(name)
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
      name = nil
      name ||= self.class.capture_arguments_name!(args, symbol: true)
      name ||= self.class.capture_arguments_name!(args, symbol: true, strict: false)
      name ||= self.class.capture_arguments_name!(args)
      name || self.class.capture_arguments_name!(args, strict: false) unless sample_n_short
    end

    # The remaining `args` received in the initialization
    def other_args(*args)
      @other_args ||= []
      if args.empty?
        @other_args
      else
        @other_args.push(*args)
      end
    end

    # It consumes `other_args`, to prevent direct overrides to be overriden by it.
    def configure_other
      if type = other_args.find {|arg| arg.is_a?(Class)}
        @type_coertion = type
        other_args.delete(type)
      end
      if value = other_args.find {|arg| arg.is_a?(String)}
        @desc = value
        other_args.dup.each do |val|
          other_args.delete(val) if val.is_a?(String)
        end
      end
      nil
    end
  end
end
