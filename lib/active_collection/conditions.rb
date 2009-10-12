module ActiveCollection
  module Conditions

    def self.conditiond(mod)
      mod.extend ClassMethods
      mod.class_eval do
        find_scope :conditions_options
      end
    end

    module ClassMethods
      def conditions(*conditions)
        write_inheritable_attribute(:default_conditions, conditions)
      end

      def default_conditions
        read_inheritable_attribute(:default_conditions) ||
          write_inheritable_attribute(:default_conditions, [])
      end

      def merge_conditions(a, b)
        (safe_to_array(a) + safe_to_array(b)).uniq
      end
    end

    def each_condition(&block)
      @conditions ||= self.class.default_conditions
    end

    def conditions(*conds)
      unloading_dup { |ac| ac.condition!(*conds) }
    end

    def condition!(*new_conditions)
      raise_if_loaded
      @conditions = self.class.merge_conditions(new_conditions, conditions).uniq
    end

    def conditions_options
      { :conditions => @conditions } unless @conditions.blank?
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
