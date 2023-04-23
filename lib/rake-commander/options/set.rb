class RakeCommander
  module Options
    class Set
      include RakeCommander::Options

      class << self
        include Enumerable

        # Name of the `Options::Set`
        def name(value = :not_used)
          return @name if value == :not_used
          @name = value.to_sym
        end

        def each(&block)
          return to_enum(:each) unless block
          options.each(&block)
        end
      end
    end
  end
end
