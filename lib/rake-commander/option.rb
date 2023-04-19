class RakeCommander
  @option_struct ||= Struct.new(:short, :name)
  class Option < @option_struct
    extend RakeCommander::Base::ClassHelpers
    extend RakeCommander::Options::Name

    attr_accessor :desc, :default
    attr_writer :type_coertion

    def initialize(short, name, *args, **kargs, &block)
      raise ArgumentError, "A short of one letter should be provided. Given: #{short}" unless short.is_a?(String)
      raise ArgumentError, "A name should be provided. Given: #{name}" unless name.is_a?(String)

      super(short, name)
      @default        = kargs[:default] if kargs.key?(:default)
      @desc           = kargs[:desc]    if kargs.key?(:desc)
      @other_args     = args
      @original_block = block
      yield(self) if block_given?
      configure_other
    end

    # @return [Symbol]
    def short
      self.class.short_sym(super)
    end

    # @return [String]
    def short_hyphen
      self.class.short_hyphen(short)
    end

    # @return [Symbol]
    def name
      self.class.name_sym(super)
    end

    # @return [String]
    def name_hyphen
      self.class.name_hyphen(name).to_s
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
    def add_switch(opts_parser, where: :base, &middleware)
      raise "Expecting OptionParser. Given: #{opts_parser.class}" unless opts_parser.is_a?(OptionParser)
      case where
      when :head, :top
        opts_parser.on_head(*switch_args, &option_block(&middleware))
      when :tail, :end
        opts_parser.on_tail(*switch_args, &option_block(&middleware))
      else # :base
        opts_parser.on(*switch_args, &option_block(&middleware))
      end
      opts_parser
    end

    # @return [Array<Variant>]
    def switch_args
      configure_other
      args = [short_hyphen, name_hyphen]
      if str = switch_desc
        args << str
      end
      args << type_coertion if type_coertion
      args
    end

    private

    # Called on parse runtime
    def option_block(&middleware)
      block_extra_args = [default, short, name]
      proc do |value|
        args = block_extra_args.dup.unshift(value)
        @original_block&.call(*args)
        middleware&.call(*args)
      end
    end

    def switch_desc
      val = "#{desc}#{default_desc}"
      return nil if val.empty?
      val
    end

    def default_desc
      return nil unless default?
      str = "Default: '#{default}'"
      if desc && !desc.downcase.include?('default')
        str = desc.end_with?('.') ? " #{str}" : ". #{str}"
      end
      str
    end

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
      if type = other_args.find {|arg| arg < Class}
        self.type_coertion = type
        other_args.delete(type)
      end
      if value = other_args.find {|arg| arg.is_a?(String)}
        self.desc = value
        other_args.dup.each do |val|
          delete(val) if val.is_a?(String)
        end
      end
      nil
    end
  end
end
