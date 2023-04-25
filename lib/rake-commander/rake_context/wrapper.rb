class RakeCommander
  module RakeContext
    class Wrapper
      include Rake::DSL

      # Allows to interact with rake
      # @note this prevents subclass overlap methods to be used
      def context(object = global_instance, &block)
        raise ArgumentError, "Block required" unless block_given?
        object.instance_eval(&block)
      end

      def respond_to_missing?(meth, *args)
        global_instance.send(:respond_to_missing?, meth, *args) || super
      end

      def respond_to?(meth, with_private = true)
        global_instance.respond_to?(meth, with_private) || super
      end

      # Forward
      def method_missing(meth, *args, **kargs, &block)
        if respond_to?(meth)
          context do
            send(meth, *args, **kargs, &block)
          end
        else
          super
        end
      end

      private


      # Refers to the top level object
      def global_instance
        @global_instance ||= eval('self', TOPLEVEL_BINDING, __FILE__, __LINE__)
      end
    end
  end
end
