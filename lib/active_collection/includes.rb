module ActiveCollection
  module Includes

    def self.included(mod)
      mod.extend ClassMethods
      mod.class_eval do
        find_scope :include_options
      end
    end

    # def self.before_save(*methods, &block)
    #   callbacks = CallbackChain.build(:before_save, *methods, &block)
    #   @before_save_callbacks ||= CallbackChain.new
    #   @before_save_callbacks.concat callbacks
    # end
    #
    # def self.before_save_callback_chain
    #   @before_save_callbacks ||= CallbackChain.new
    #
    #   if superclass.respond_to?(:before_save_callback_chain)
    #     CallbackChain.new(
    #       superclass.before_save_callback_chain +
    #       @before_save_callbacks
    #     )
    #   else
    #     @before_save_callbacks
    #   end
    # end

    module ClassMethods
      def includes(*new_includes)
        @default_includes = merge_includes(@default_includes || [], new_includes)
      end

      def default_includes
        @default_includes ||= []
        if superclass != ActiveCollection::Base
          merge_includes(superclass.default_includes, @default_includes)
        else
          @default_includes
        end
      end

      def merge_includes(a, b)
        (safe_to_array(a) + safe_to_array(b)).flatten.uniq
      end

      protected

      # Taken from ActiveRecord::Base
      #
      # Object#to_a is deprecated, though it does have the desired behavior
      def safe_to_array(o)
        case o
        when NilClass
          []
        when Array
          o
        else
          [o]
        end
      end
    end

    def includes
      @includes ||= []
    end

    def include(*new_includes)
      unloading_dup { |ac| ac.include! *new_includes }
    end

    def include!(*new_includes)
      raise_if_loaded
      @includes = self.class.merge_includes(includes, new_includes)
    end

    def include_options
      incs = self.class.merge_includes(self.class.default_includes, includes)
      { :include => incs } unless incs.blank?
    end

  end
end
