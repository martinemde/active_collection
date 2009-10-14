# Lazy-loaded collection of records
# Behaves like an Array or Hash (where bang methods alter self)
module ActiveCollection
  # Raised when a mutating method is called on an already loaded collection.
  class AlreadyLoadedError < StandardError #:nodoc:
  end

  class Base
    #instance_methods.each do |m|
    #  unless m =~ /(^__|^proxy_)/ || %w[should should_not nil? send dup extend inspect object_id].include?(m)
    #    undef_method m
    #  end
    #end
    
    include Enumerable

    attr_reader :params

    # Create a Collection by passing the important query params from
    # the controller.
    #
    # Example:
    #
    #     BeerCollection.new(params.only("q","page"))
    #
    # If any :page parameter is passed, nil or not, the assumption will be that
    # the collection should be a paged collection and the current_page will
    # default to 1.
    def initialize(params = {})
      @params = params.symbolize_keys
    end

    alias_method :proxy_respond_to?, :respond_to?

    # Does the ActiveCollection or it's target collection respond to method?
    def respond_to?(*args)
      proxy_respond_to?(*args) || collection.respond_to?(*args)
    end

    # Forwards <tt>===</tt> explicitly to the collection because the instance method
    # removal above doesn't catch it. Loads the collection if needed.
    def ===(other)
      other === collection
    end

    def send(method, *args)
      if proxy_respond_to?(method)
        super
      else
        collection.send(method, *args)
      end
    end

    # dup that doesn't include the collection if it's loaded
    def unloading_dup
      d = dup
      d.unload!
      yield d if block_given?
      d
    end

    # Implements Enumerable
    def each(&block)
      collection.each(&block)
    end

    # The emptiness of the collection (limited by query and pagination)
    def empty?
      size.zero?
    end

    # The size of the collection (limited by query and pagination)
    #
    # It will avoid using a count query if the collection is already loaded.
    #
    # (Note that the paginated count is added in the pagination module)
    def size
      loaded?? length : total_entries
    end

    # Always returns the total count of all records that can be in this collection.
    def total_entries
      @total_entries ||= load_count
    end

    # The size of the collection (limited by query and pagination)
    #
    # Similar to ActiveRecord associations, length will always load the collection.
    def length
      collection.size
    end

    # true if the collection data has been loaded
    def loaded?
      !!@collection
    end

    def unload!
      @collection = nil
    end

    protected

    # Pass methods on to the collection.
    def method_missing(method, *args)
      if Array.method_defined?(method) && !Object.method_defined?(method)
        if block_given?
          collection.send(method, *args)  { |*block_args| yield(*block_args) }
        else
          collection.send(method, *args)
        end
      else
        super
        #message = "undefined method `#{method.to_s}' for \"#{collection}\":#{collection.class.to_s}"
        #raise NoMethodError, message
      end
    end

    # The actual collection data. Must be memoized or you'll access data over
    # and over and over again.
    def collection
      @collection ||= load_collection
    end

    def load_count
      model_class.count(count_options)
    end

    # Overload this method to change the way the collection is loaded.
    def load_collection
      model_class.all(find_options)
    end

    # Raises an AlreadyLoadedError if the collection has already been loaded
    def raise_if_loaded
      raise AlreadyLoadedError, "Cannot modify a collection that has already been loaded." if loaded?
    end
  end

  Base.class_eval do
    include MemberClass
    include Scope
    include Includes, Order, Pagination, Serialization
  end
end
