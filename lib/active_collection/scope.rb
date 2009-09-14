require 'active_support/core_ext/array/extract_options'

module ActiveCollection
  module Scope
    #extend ActiveSupport::Concern

    def self.included(mod)
      mod.extend ClassMethods
    end

    # Find options for loading the collection.
    #
    # To add more options, define a method that returns a hash with the
    # additional options for find and then add it like this:
    #
    #   class BeerCollection
    #     find_scope :awesome_beer_only
    #
    #     def awesome_beer_only
    #       { :conditions => "beer = 'awesome'" }
    #     end
    #   end
    #
    def find_options
      self.class.scope_for_find.to_options(self)
    end

    # Count options for loading the total count.
    #
    # To add more options, define a method that returns a hash with the
    # additional options for count and then add it like this:
    #
    #   class BeerCollection
    #     count_scope :awesome_beer_only
    #
    #     def awesome_beer_only
    #       { :conditions => "beer = 'awesome'" }
    #     end
    #   end
    #
    def count_options
      self.class.scope_for_count.to_options(self)
    end

    module ClassMethods
      def scope_for_find
        ScopeBuilder.new(scope_builder + find_scope_builder)
      end

      def scope_for_count
        ScopeBuilder.new(scope_builder + count_scope_builder)
      end

      [:scope, :find_scope, :count_scope].each do |scope|
        module_eval <<-SCOPE, __FILE__, __LINE__
          def #{scope}(*methods, &block)
            #{scope} = ScopeBuilder.build(:#{scope}, *methods, &block)
            @#{scope}_builder ||= ScopeBuilder.new
            @#{scope}_builder.concat #{scope}
          end

          def #{scope}_builder
            @#{scope}_builder ||= ScopeBuilder.new
            if superclass.respond_to?(:#{scope}_builder)
              superclass.#{scope}_builder + @#{scope}_builder
            else
              @#{scope}_builder
            end
          end
        SCOPE
      end
    end

    class ScopeBuilder < Array
      def self.build(kind, *methods, &block)
        methods, options = extract_options(*methods, &block)
        methods.map! { |method| ActiveSupport::Callbacks::Callback.new(kind, method, options) }
        new(methods)
      end

      def to_options(object)
        inject({}) { |h, callback| h.merge( callback.call(object) ) }
      end

      private
        def self.extract_options(*methods, &block)
          methods.flatten!
          options = methods.extract_options!
          methods << block if block_given?
          return methods, options
        end
    end
  end
end

