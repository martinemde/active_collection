module ActiveCollection
  module MemberClass
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def model_class
        @model_class ||= name.sub(/Collection$/,'').constantize
      end

      def table_name
        model_class.table_name
      end

      def human_name(*args)
        model_class.human_name(*args).pluralize
      end
    end

    def model_class
      self.class.model_class
    end

    def table_name
      self.class.table_name
    end

    def human_name(*args)
      self.class.human_name(*args)
    end
  end
end
