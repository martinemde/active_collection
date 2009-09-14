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

    def self.model_class
      @model_class ||= name.sub(/Collection$/,'').constantize
    end

    def model_class
      self.class.model_class
    end

    def self.table_name
      model_class.table_name
    end

    def table_name
      self.class.table_name
    end

    def self.human_name
      table_name.gsub(/_/,' ')
    end

    def human_name
      self.class.human_name
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

    # Turn the params into a hash suitable for passing the collection directly as an arg to a named path.
    def to_param
      params.empty?? nil : params.to_param
    end

    def as_data_hash
      data_hash = { "collection" => collection.as_json }
      data_hash["total_entries"] = total_entries
      data_hash
    end

    def to_xml(options = {})
      collect
      options[:indent] ||= 2
      xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
      xml.instruct! unless options[:skip_instruct]
      xml.tag!(table_name) do
        xml.total_entries(total_entries, :type => "integer")
        xml.collection(:type => "array") do
          collection.each do |item|
            item.to_xml(:indent => options[:indent], :builder => xml, :skip_instruct => true)
          end
        end
      end
    end

    def as_json(options = nil)
      {table_name => as_data_hash}.as_json(options)
    end

    # Implements Enumerable
    def each(&block)
      collection.each(&block)
    end

    # Grab the raw collection.
    def all
      collection
    end

    # The emptiness of the collection (limited by query and pagination)
    def empty?
      size.zero?
    end

    # The size of the collection (limited by query and pagination)
    #
    # It will avoid using a count query if the collection is already loaded.
    def size
      loaded?? collection.size : total_entries
    end

    # Always returns the total count regardless of pagination.
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

    protected

    # Pass methods on to the collection.
    def method_missing(method, *args)
      if Array.method_defined?(method) && !Object.method_defined?(method)
        raise "#{method} received with #{args.join(', ')}"
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

    # Overload this method to add extra find options.
    #
    # :offset and :limit will be overwritten by the pagination_options if the
    # collection is paginated, because you shouldn't be changing the paging
    # directly if you're working with a paginated collection
    # 
    def query_options
      {}
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

    # Extracted from AR:B
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

  Base.class_eval do
    include Scope
    include Includes, Order, Pagination
  end
end