module ActiveCollection
  module Order

    def self.included(mod)
      mod.extend ClassMethods
      mod.class_eval do
        find_scope :order_options
      end
    end

    module ClassMethods
      def order_by(order = "id ASC")
        @order = order
      end

      def default_order
        @order || (superclass != ActiveCollection::Base && superclass.default_order) || nil
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
      ord = @order || self.class.default_order
      { :order => ord } if ord
    end
  end
end
