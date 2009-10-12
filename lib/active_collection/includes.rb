module ActiveCollection
  module Includes

    def self.included(mod)
      mod.extend ClassMethods
      mod.class_eval do
        find_scope :include_options
      end
    end

    module ClassMethods
      def includes(*includes)
        write_inheritable_attribute(:default_includes, includes)
      end

      def default_includes
        read_inheritable_attribute(:default_includes) || []
      end
    end

    def includes
      @includes ||= self.class.default_includes
    end

    def include(*new_includes)
      ac = unloading_dup
      ac.include! *new_includes
      ac
    end

    def include!(*new_includes)
      raise_if_loaded
      @includes = (safe_to_array(new_includes) + safe_to_array(includes)).uniq
    end

    def include_options
      { :include => @includes } unless @includes.blank?
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
end
