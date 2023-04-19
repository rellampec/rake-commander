class RakeCommander
  module Options
    class Set
      include RakeCommander::Options

      class << self
        include Enumerable

        def each(&block)
          return to_enum(:each) unless block
          options.values.each(&block)
        end
      end
    end
  end
end
