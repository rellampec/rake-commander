class RakeCommander
  module Options
    # Offers helpers to treat `ARGV`
    module Arguments
      include RakeCommander::Options::Name
      NAME_ARGUMENT    = /^--(?<option>[\w_-]*).*?$/.freeze
      BOOLEAN_ARGUMENT = /(?:^|--)no-(?<option>[\w_-]*).*?$/.freeze

      # Options with arguments should not take another option as value.
      # `OptionParser` can do this even if the the argument is optional.
      # This method re-arranges the arguments based on options that receive parameters,
      # provided that an option is not taken as a value of a previous option that accepts arguments.
      # If an option with argument is missing the argument, but has a `default` value,
      # that `default` value will be inserted after the option in the array
      # to prevent the `OptionParser::MissingArgument` error to stop the parsing process.
      # @note
      #   1. Any word or letter with _hypen_ -`` or _double hypen_ `--` is interpreted as option(s)
      #   2. To overcome this limitation, you may enclose in double quotes and argument with
      #     that start (i,e, `"--argument"`).
      # @example
      #   1. `-abc ARGUMENT` where only `c` receives the argument becomes `-ab -c ARGUMENT`
      #   3. `-abc ARGUMENT` where `b` and `c` are argument receivers becomes `-a -b nil -c ARGUMENT`
      #   2. `-acb ARGUMENT` where only `c` receives the argument becomes `-a -c nil -b ARGUMENT`
      #   4. `-c --some-option ARGUMENT` where both options receive argument, becomes `-c nil --some-option ARGUMENT`
      #   5. `-c --some-option -d ARGUMENT` where both options receive argument, becomes `-c nil --some-option nil -d ARGUMENT`
      #   6. `-cd ARGUMENT` where `c` default is `"yeah"`, becomes `-c yeah -d ARGUMENT`
      # @param argv [Array<String>]
      # @param options [Hash] the defined `RakeCommander::Option` to re-arrange `argv` with.
      # @return [Array<String>] the re-arranged `argv`
      def pre_parse_arguments(argv = ARGV, options:)
        pre_parsed = explicit_argument_options(argv, options)
        compact_short = ''
        pre_parsed.each_with_object([]) do |(opt_ref, args), out|
          next out.push(*args) unless opt_ref.is_a?(Symbol)
          is_short = opt_ref.to_s.length == 1
          next compact_short << opt_ref.to_s if is_short && args.empty?
          out.push("-#{compact_short}") unless compact_short.empty?
          compact_short = ''
          opt_str = is_short ? "-#{opt_ref}" : name_hyphen(opt_ref)
          out.push(opt_str, *args)
        end.tap do |out|
          out.push("-#{compact_short}") unless compact_short.empty?
        end
      end

      private

      # @example the output is actually a Hash, keyed by the Symbol of the option (short or name)
      #   1. `-abc ARGUMENT` where only `c` receives the argument becomes `:a :b :c ARGUMENT`
      #   3. `-abc ARGUMENT` where `b` and `c` are argument receivers becomes `:a :b nil :c ARGUMENT`
      #   2. `-acb ARGUMENT` where only `c` receives the argument becomes `:a :c nil :b ARGUMENT`
      #   4. `-c --some-option ARGUMENT` where both options receive argument, becomes `:c nil :some_option ARGUMENT`
      #   5. `-c --some-option -d ARGUMENT` where first two options receive argument, becomes `:c nil :some_option nil :d ARGUMENT`
      #   6. `-cd ARGUMENT` where `c` default is `"yeah"`, becomes `:c yeah :d ARGUMENT`
      # @return [Hash<Symbol, Array>]
      def explicit_argument_options(argv, options)
        decoupled  = decluster_shorts_n_names_to_sym(argv)
        grouped    = group_symbols_with_strings(decoupled)
        normalized = insert_missing_argument_to_groups(grouped, options)
        normalized.each_with_object({}) do |group, pre_parsed|
          opt_ref = group.first.is_a?(Symbol)? group.shift : nil
          pre_parsed[opt_ref] = group
        end
      end

      # It adds the missing argument to options that expect it.
      # @note it uses `default` if present, and `nil` otherwise.
      # @param groups [@see #pair_symbols_with_strings]
      def insert_missing_argument_to_groups(groups, options)
        groups.each do |group|
          args = group.dup
          opt_ref = args.shift
          next unless args.empty?
          next unless opt_ref.is_a?(Symbol)
          unless opt = options[opt_ref]
            # It might be `--no-option-name`
            next unless match   = opt_ref.to_s.match(BOOLEAN_ARGUMENT)
            next unless opt_ref = match[:option]
            next unless opt     = options[opt_ref.to_sym]
            next unless opt.boolean_name?
          end
          next unless opt.argument?
          next group.push(opt.default) if opt.default?
          group.push(nil)
        end
      end

      # @return [Array<Array>] where the first element of each `Array` is a symbol
      #   followed by one or more `String`.
      def group_symbols_with_strings(argv)
        [].tap do |out|
          curr_ary = nil
          argv.each do |arg|
            if arg.is_a?(Symbol)
              out << (curr_ary = [arg])
            else # must be `String`
              out << (curr_ary = []) unless curr_ary
              curr_ary << arg
            end
          end
        end
      end

      # It splits `argv` compacted shorts into their `Symbol` version.
      # Symbolizes option `names` (long version).
      # @return [Array<String, Symbol>] where symbols are options and strings arguments.
      def decluster_shorts_n_names_to_sym(argv)
        argv.each_with_object([]) do |arg, out|
          if single_hyphen?(arg) # short option(s)
            options = arg.match(SINGLE_HYPHEN_REGEX)[:options]
            options.split('').each do |short|
              out << short_sym(short)
            end
          elsif double_hyphen?(arg) # name option
            name = arg.match(NAME_ARGUMENT)[:option]
            out << name_sym(name)
          else # argument
            out << arg
          end
        end
      end
    end
  end
end
