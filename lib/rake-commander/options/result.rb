class RakeCommander
  module Options
    module Result
      class << self
        def included(base)
          super
          base.extend ClassMethods
          base.attr_inheritable :options_with_defaults
        end
      end

      module ClassMethods
        # Configuration Setting.
        # @return [Boolean] whether results should include options defined
        #   with a default, regarless if they are invoked
        def options_with_defaults(value = nil)
          if value.nil?
            @options_with_defaults || false
          else
            @options_with_defaults = !!value
          end
        end

        # It **re-opens** the method and adds a middleware to gather and return
        # the results of the parsing (including the `leftovers`)
        # @note this extends the method parameters and changes the returned value.
        # @yield [value, default, short, name, option] do somethin  with parsed `value` for `option`
        # @yieldparam value [] the resulting parsed value
        # @yieldparam default [] the default value of the option
        # @yieldparam short [Symbol] the symbol short of the option
        # @yieldparam name [Symbol] the symbol name of the option
        # @yieldparam option [RakeCommander::Option] the option that is being parsed
        # @param leftovers [Array<String>] see RakeCommander::Options#parse_options`
        # @param results [Hash] with `short` option as `key` and final value as `value`.
        # @see `RakeCommander::Options#parse_options`
        def parse_options(argv = ARGV, results: {}, leftovers: [], &middleware)
          leftovers.push(
            *super(
              argv,
              &results_collector(results, &middleware)
            )
          )
        end

        # **Extend** method to ensure options are parsed before calling task.
        # This only happens if `task_method` has it's context (binding) with
        # an instance object of this class.
        # @note
        #   1. This allows stop before invoking the task, may there be options
        #     that have this effect (i.e. `-h`)
        #   2. We use `task_context` to open up extensibility.
        # @todo think if it should rather raise an `ArgumentError` when the task
        #   was not defined in an instance object of his class.
        def install_task(&task_method) # rubocop:disable Naming/BlockForwarding
          super(&task_context(&task_method))
        end

        protected

        # Invoke `options` parsing before calling the task.
        # @return [Proc] our wrapped task block.
        def task_context(&task_method)
          instance = eval('self', task_method.binding, __FILE__, __LINE__)
          return task_method unless instance.is_a?(self)

          proc do |*task_args|
            # launch `ARGV` parsing
            instance.options
            task_method.call(*task_args)
          end
        end

        private

        # Expects a block that should do the final call to `OptionParser#parse`.
        # It is invoked on each option parsing (so only when that option is invoked).
        # @note if an invoked option comes empty (`nil`), it uses the `default` value.
        # @return [Proc] the results collector that wraps the middleware.
        def results_collector(results, &middleware)
          results = result_defaults(results)

          proc do |value, default, short, name, opt|
            middleware&.call(value, default, short, name, opt)
            results[name] = results[short] = value.nil?? default : value
          end
        end

        # Based on `required` options, it sets the `default`
        def result_defaults(results = {})
          results.tap do |res_def|
            options.select do |opt|
              (options_with_defaults && opt.default?) \
              || (opt.required? && opt.default?)
            end.each do |opt|
              res_def[opt.name] = res_def[opt.short] = opt.default
            end
          end
        end
      end

      # INSTANCE METHODS

      # Launches the options parsing of this class.
      # @return [Hash] keyed by short.
      def options(argv = ARGV, &block) # rubocop:disable Naming/BlockForwarding
        return @options if instance_variable_defined?(:@options)

        @options = {}
        self.class.parse_options(
          argv,
          results:   @options,
          leftovers: options_leftovers,
          &block
        )

        @options
      end

      # The options part (so after `--`) that was NOT processed
      # by the `OptionParser`. They are therefore unknown parameters.
      # @note an unknown option (i.e. `-f something`, `--foo something`) would trigger an invalid option error.
      #   This means that the `leftovers` can only refer to arguments not paired to options that receive
      #   parameters (i.e. `--no-foo something`).
      def options_leftovers
        @options_leftovers ||= []
      end
    end
  end
end
