class RakeCommander
  module Patcher
    # Helpers to patch
    module Helpers
      # For a given method `meth` it gives the index of the parameter `arg_name`
      # @return [Integer, NilClass] the position of `arg_name` in parameters.
      def method_argument_idx(meth, arg_name)
        arg_name = arg_name.to_sym
        meth.parameters.each_with_index do |(_type, name), i|
          return i if name == arg_name
        end
      end

      # Its usage only makes sense if you extended an existing method you are patching.
      # Therefore it is expected that `super` exists, so the original parameters definition
      # of the method can be accessed.
      # @note although the signature of a method can change through different versions
      #   the name of the parameters is generally preserved (specially when they are core parameters).
      # @example
      #     module Rake
      #       class Application
      #         def init(*args)
      #           args = RakeCommander::Patcher.change_method_argument(:argv, method: method(__method__), args: args) do |value|
      #             RakeCommander.argv_rake_native_arguments(value)
      #           end
      #           super(*args)
      #         end
      #       end
      #     end
      #
      # @param arg_name [Symbol, String] the name of the parameter as it reads in the original method.
      # @param method [Method] the extended method (not its `super` method)
      # @return [Array] the original arguments where `arg_name` has been changed.
      def change_method_argument(arg_name, method:, args:)
        raise ArgumentError, 'Expecting block' unless block_given?
        raise ArgumentError, "Expecting Method. Given #{method.class}" unless method.is_a?(Method)
        if idx = method_argument_idx(method.super_method, arg_name.to_sym)
          args[idx] = yield(args[idx])
        end
        args
      end
    end
  end
end
