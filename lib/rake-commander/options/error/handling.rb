class RakeCommander
  module Options
    module Error
      module Handling
        class << self
          def included(base)
            super

            base.extend RakeCommander::Base::ClassHelpers
            base.extend RakeCommander::Base::ClassInheritable
            base.extend ClassMethods
            base.attr_inheritable :error_on_options, :error_on_options_handler
          end
        end

        module ClassMethods
          attr_reader :options_latest_error

          # Whether it should trigger an error when there are `ARGV` option errors during `parse_options`
          # @note
          #   1. It triggers error by default when there are parsing option errors.
          #   2. Even if a `handler` block is defined, if action is `false` it won't trigger error.
          #   3. When specific errors are NOT specified, they will **fallback** to the action defined
          #     on the parent class `RakeCommander::Options::Error::Base`. This means that you can define
          #     a default behaviour for this.
          # @raise [RakeCommander::Options::Error::Base] the specific option error that was raised.
          #   1. when `action` is `true` (default)
          #   2. when the `handler` is defined and returns `true`.
          # @yield [error, argv, results, leftovers] do some stuff and decide if an error should be raised.
          # @yieldparam error [RakeCommander::Options::Error::Base] the specific error.
          # @yieldparam argv [Array<String>] arguments that were being parsed.
          # @yieldparam results [Hash] the parsed options.
          # @yieldparam leftovers [Array<String>] arguments of `argv` that the parser could not identify.
          # @yieldreturn [Boolean] whether this should trigger an error or not.
          # @param action [Boolean, Symbol] possible values are:
          #   1. `:not_used`      -> it will retrieve the currect action value
          #   2. `true` (default) -> it switches `on` the exception triggering
          #   3. `false`          -> it will **print** the error and **exit** with status `1`
          #   4. `:continue`      -> it will continue with whatver it got (**use this at your own risk**)
          # @param error [RakeCommander::Options::Error::Base:Class] or children thereof.
          # @return [Boolean] whether this error is enabled.
          def error_on_options(action = :not_used, error: RakeCommander::Options::Error::Base, &handler)
            RakeCommander::Options::Error::Base.require_argument!(error, :error, accept_children: true)
            @options_latest_error       = nil
            @error_on_options         ||= {}
            @error_on_options[error]    = action if action != :not_used

            if block_given?
              error_on_options_handler(error, &handler)
              @error_on_options[error] ||= true
            end

            return self unless block_given? || action != :not_used
            # default value
            @error_on_options[error] = true unless @error_on_options[error] == false
            @error_on_options[error]
          end

          # @see #error_on_options
          def error_on_leftovers(action = :not_used, &handler)
            error_on_options(action, error: RakeCommander::Options::Error::UnknownArgument, &handler)
          end

          # @return [Boolean] whether there is an error `action` defined for `error`
          def error_on_options?(error = RakeCommander::Options::Error::Base)
            RakeCommander::Options::Error::Base.require_argument!(error, :error, accept_children: true)
            _default_action = error_on_options
            @error_on_options.key?(error) || error_on_options_handler.key?(error)
          end

          protected

          # Provide error for the given block.
          # @return [String<Array>] the result of `yield` or `leftovers` if there was an error
          #   where the `action` was defined as `:continue`
          def with_error_handling(argv, results, leftovers)
            yield
          rescue RakeCommander::Options::Error::Base => e
            @options_latest_error = e
            eklass                = e.class
            # Fallback to generic error handling if specific error action is not defined
            eklass = eklass.superclass unless error_on_options?(eklass)
            action = error_on_options(error: eklass)

            # here is where we ignore the handler (when !action == `true`)
            raise            unless !action || (handler = error_on_options_handler(eklass))
            raise            if handler&.call(e, argv, results, leftovers)
            return leftovers if action == :continue

            puts e.message
            # https://stackoverflow.com/a/23340693/4352306
            exit 1
          end

          private

          def error_on_options_handler(error = :not_used, &handler)
            @error_on_options_handler        ||= {}
            return @error_on_options_handler if error == :not_used

            RakeCommander::Options::Error::Base.require_argument!(
              error,
              :error,
              accept_children: true
            )

            @error_on_options_handler[error] = handler if block_given?
            @error_on_options_handler[error]
          end
        end
      end
    end
  end
end
