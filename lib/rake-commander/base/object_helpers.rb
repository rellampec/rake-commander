class RakeCommander
  module Base
    module ObjectHelpers
      private

      # Custom Object#deep_dup for rake commander
      def custom_deep_dup(value, dup_objects: true, &dup_block)
        case value
        when Hash
          custom_hash_deep_dup(value, dup_objects: dup_objects, &dup_block)
        when Array
          value.map {|v| custom_deep_dup(v, dup_objects: dup_objects, &dup_block)}
        else
          custom_object_deep_dup(value, dup_objects: true, &dup_block)
        end
      end

      # Does the copy of the final object
      def custom_object_deep_dup(value, dup_objects: true)
        return yield(value)   if block_given?
        return value          unless dup_objects
        return value.deep_dup if value.respond_to?(:deep_dup)

        value.dup
      end

      # Custom Hash#deep_dup for rake commander
      def custom_hash_deep_dup(original, dup_objects: true, &dup_block)
        raise ArgumentError, "Expecting Hash. Given: #{original.class}" unless original.is_a?(Hash)

        hash = original.dup

        original.each_pair do |key, value|
          unless key.frozen? && key.is_a?(::String)
            hash.delete(key)
            key = custom_deep_dup(key, dup_objects: dup_objects, &dup_block) if dup_objects
          end

          value     = custom_deep_dup(value, dup_objects: dup_objects, &dup_block) if dup_objects
          hash[key] = value
        end

        hash
      end
    end
  end
end
