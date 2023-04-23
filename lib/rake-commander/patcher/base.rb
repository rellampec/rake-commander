class RakeCommander
  module Patcher
    # Base of self-applied patchers.
    # @note a patcher will be applied when it's included.
    module Base
      class << self
        def included(base)
          super(base)
          base.extend ClassMethods
        end
      end

      module ClassMethods
        def included(base)
          super(base)
          base.extend self::ClassMethods if defined?(self::ClassMethods)
          invoke_patch_methods!(base) unless self == RakeCommander::Patcher::Base
        end

        def invoke_patch_methods!(base)
          raise "#{self}: no patch methods. Patching with include requires at least one." unless any_patch_method?
          patch_prepend(base) if patch_prepend?
          patch_include(base) if patch_include?
          patch_extend(base)  if patch_extend?
        end

        def any_patch_method?
          patch_prepend? || patch_include? || patch_extend?
        end

        def patch_prepend?
          respond_to?(:patch_prepend)
        end

        def patch_include?
          respond_to?(:patch_include)
        end

        def patch_extend?
          respond_to?(:patch_extend)
        end
      end
    end
  end
end
