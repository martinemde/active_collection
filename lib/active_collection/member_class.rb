module ActiveCollection
  module MemberClass
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      #
      # If the name of the class held by your collection cannot be derived from
      # the name of the collection class (by removing the word Collection from
      # the end of the collection class name) then use model to set it.
      #
      # Example:
      #
      #     class WeirdNamedCollection
      #       model "Normal"
      #     end
      # 
      # This will use the class Normal to do counts and finds.
      def model(class_name)
        (@model_class_name = class_name) && @model_class = nil
      end

      # The actual member class.
      #
      # Prints a useful error message if you define your model class wrong.
      def model_class
        begin
          @model_class ||= model_class_name.constantize
        rescue NameError => e
          raise NameError, %|#{e} - Use 'model "Class"' in the collection to declare the correct model class for #{name}|
        end
      end

      # Table name of the member class.
      def table_name
        model_class.table_name
      end

      # Plural human name of the member class.
      def human_name(*args)
        model_class.human_name(*args).pluralize
      end

      protected

      def model_class_name
        @model_class_name || name.sub(/Collection$/,'')
      end
    end

    # The actual member class.
    def model_class
      self.class.model_class
    end

    # Table name of the member class.
    def table_name
      self.class.table_name
    end

    # Plural human name of the member class.
    def human_name(*args)
      self.class.human_name(*args)
    end
  end
end
