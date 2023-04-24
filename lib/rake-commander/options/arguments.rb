class RakeCommander
  module Options
    # Offers helpers to treat `ARGV`
    module Arguments
      RAKE_COMMAND_EXTENDED_OPTIONS_START = '--'.freeze
      NAME_ARGUMENT    = /^--(?<option>[\w_-]*).*?$/.freeze
      BOOLEAN_ARGUMENT = /(?:^|--)no-(?<option>[\w_-]*).*?$/.freeze

      class << self
        def included(base)
          super(base)
          base.extend ClassMethods
        end
      end

      module ClassMethods
        include RakeCommander::Options::Name

        # Configuration setting
        # Whether the additional arguments (extended options) managed by this gem
        # should be removed/consumed from `ARGV` before `Rake` processes option arguments.
        # @note
        #   1. When `true` it **will enable**
        #     * A **patch** on `Rake::Application`**, provided that `ARGV` is cropped
        #       before `Rake` identifies **tasks** and rake native **options**.
        #       Note that this specific patch only works if rake commander was loaded
        #       BEFORE `Rake::Application#run` is invoked.
        #   2. When `false`, an implicit `exit(0)` is added at the end of a rake task
        #     defined via `RakeCommander`, as a work-around that prevents `Rake` from
        #     chaining option arguments as if they were actual tasks.
        # @note
        #   1. This only refers to what comes after `RAKE_COMMAND_EXTENDED_OPTIONS_START` (`--`)
        # @return [Boolean]
        def argv_cropping_for_rake(value = :not_used)
          @argv_cropping_for_rake = true if @argv_cropping_for_rake.nil?
          return @argv_cropping_for_rake if value == :not_used
          @argv_cropping_for_rake = !!value
        end

        # It returns the part of `ARGV` that are arguments of `RakeCommander::Options` parsing.
        # @note please observe that `Rake` has it's own options. For this reason using
        #   a delimiter (`RAKE_COMMAND_EXTENDED_OPTIONS_START`) shows up to be necessary to
        #   create some sort of command line argument namespacing.
        # @param argv [Array<String>] the command line arguments array.
        # @return [Array<String>] the target arguments to be parsed by `RakeCommander::Options`
        def argv_extended_options(argv = ARGV.dup)
          if idx = argv.index(RAKE_COMMAND_EXTENDED_OPTIONS_START)
            argv = argv[idx+1..-1]
          end
          argv
        end

        # It slices from the original `ARGV` the extended_options of this gem.
        # @note this is necessary to prevent `Rake` to interpret them.
        # @return [Array<String>] the argv without the extended options of this gem.
        def argv_rake_native_arguments(argv = ARGV.dup)
          return argv unless argv_cropping_for_rake
          if idx = argv.index(RAKE_COMMAND_EXTENDED_OPTIONS_START)
            argv = argv[0..idx]
          end
          argv
        end

        # **Re-open** `parse_options` method, provided that we slice `ARGV`
        # to only include the extended options of this gem, which start at
        # `RAKE_COMMAND_EXTENDED_OPTIONS_START`.
        # @note
        #   1. Without this `ARGV` cut, it will throw `OptionParser::InvalidOption` error
        #     - So some tidy up is necessary and the head of the command (i.e. `rake some:task --`)
        #       should be excluded from arguments to input to the options parser.
        # @see `RakeCommander::Options#parse_options`
        def parse_options(argv = ARGV, *args, **kargs, &block)
          argv = argv_extended_options(argv)
          argv = argv_pre_parsed(argv, options: options_hash(with_implicit: true))
          super(argv, *args, **kargs, &block)
        end

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
        def argv_pre_parsed(argv = ARGV, options:)
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

        protected

        # It wraps the `task_method` to check if the patch to crop `ARGV` is active.
        # If it's not active it will call `exit(0)` at the end of the task run, to prevent
        # `Rake` from interpreting option arguments as rake tasks.
        # @note **reopens** `RakeCommander::RakeTask` method
        #   * If `argv_cropping_for_rake` is `false` it calls `exit(0)` right at the end of the task.
        #   * This relates on whether the patch to `Rake::Application` has been applied.
        # @return [Proc] the wrapped block.
        def task_context(&task_method)
          proc do |*task_args|
            super(&task_method).call(*task_args)
            exit(0) unless argv_cropping_for_rake
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
        # @note
        #  1. It uses `default` if present, and `nil` otherwise.
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
end
