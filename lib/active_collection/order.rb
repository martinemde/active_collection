module ActiveCollection
  module Order

    def self.included(mod)
      mod.extend ClassMethods
      mod.class_eval do
        find_scope :order_options
      end
    end

    def order
      @order ||= self.class.default_order
    end

    def order_by(order)
      ac = unloading_dup
      ac.order_by! order
      ac
    end

    def order_by!(order)
      raise_if_loaded
      @order = order
    end

    def order_options
      { :order => order } if order
    end

    module ClassMethods
      def order_by(order = "id ASC")
        write_inheritable_attribute(:default_order, order)
      end

      def default_order
        read_inheritable_attribute(:default_order) || nil
      end
    end
  end
end
