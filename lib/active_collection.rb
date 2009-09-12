# Lazy-loaded collection of records
# Behaves like an Array or Hash (where bang methods alter self)
class ActiveCollection
  class AlreadyLoadedError < StandardError; end

  alias_method :proxy_respond_to?, :respond_to?
  alias_method :proxy_class, :class
  instance_methods.each do |m|
    unless m =~ /(^__|^proxy_)/ || %w[nil? send dup extend inspect object_id].include?(m)
      undef_method m
    end
  end

  include Enumerable

  attr_reader :params, :current_page

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
    @current_page = params.has_key?(:page) ? (params[:page] || 1).to_i : nil
    @includes = self.proxy_class.default_includes
    @order = self.proxy_class.default_order
  end

  def self.order_by(order = "id ASC")
    write_inheritable_attribute(:default_order, order)
  end

  def self.default_order
    read_inheritable_attribute(:default_order) || nil
  end

  def self.includes(*includes)
    write_inheritable_attribute(:default_includes, includes)
  end

  def self.default_includes
    read_inheritable_attribute(:default_includes) || []
  end

  # Does the proxy or its collection respond to +symbol+?
  def respond_to?(*args)
    proxy_respond_to?(*args) || collection.respond_to?(*args)
  end

  def self.model_class
    @model_class ||= name.sub(/Collection$/,'').constantize
  end

  def model_class
    self.proxy_class.model_class
  end

  def self.table_name
    model_class.table_name
  end

  def table_name
    self.proxy_class.table_name
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
    if paginated?
      data_hash["total_entries"] = total_entries
      data_hash["page"] = current_page
      data_hash["per_page"] = per_page
      data_hash["total_pages"] = total_pages
    end
    data_hash
  end

  def to_xml(options = {})
    collect
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.tag!(table_name) do
      if paginated?
        xml.total_entries(total_entries, :type => "integer")
        xml.page(current_page, :type => "integer")
        xml.per_page(per_page, :type => "integer")
        xml.total_pages(total_pages, :type => "integer")
      end
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
  #
  # It will avoid using a count query if the collection is already loaded.
  def empty?
    @collection ? @collection.empty? : count.zero?
  end

  # The size of the collection (limited by query and pagination)
  #
  # It will avoid using a count query if the collection is already loaded.
  def size
    @collection ? @collection.size : count
  end
  alias_method :length, :size

  # Create a new collection for the page specified
  #
  # Optionally accepts a per page parameter which will override the default
  # per_page for the new collection (without changing the current collection).
  def page(pg, per = self.per_page)
    new_collection = self.proxy_class.new(params.merge(:page => pg))
    new_collection.per_page = per
    new_collection
  end

  def order_by(order)
    arc = dup
    arc.order_by! order
    arc
  end

  def order_by!(order = "`#{table_name}`.`id` DESC")
    raise_if_loaded
    @order = order
  end

  def include!(*includes)
    raise_if_loaded
    @includes = (safe_to_array(@includes) + safe_to_array(includes)).uniq
  end

  # The records per_page for this collection.
  #
  # Defaults to the model class' per_page.
  def per_page
    @per_page ||= model_class.per_page
  end
  attr_writer :per_page

  # Helper method that is true when someone tries to fetch a page with a
  # larger number than the last page. Can be used in combination with flashes
  # and redirecting.
  def out_of_bounds?
    current_page > total_pages
  end

  # Current offset of the paginated collection. If we're on the first page,
  # it is always 0. If we're on the 2nd page and there are 30 entries per page,
  # the offset is 30. This property is useful if you want to render ordinals
  # side by side with records in the view: simply start with offset + 1.
  def offset
    (current_page - 1) * per_page
  end

  # current_page - 1 or nil if there is no previous page
  #
  # will_paginate compatible
  def previous_page
    current_page > 1 ? (current_page - 1) : nil
  end

  # ActiveRecord::Collection for current_page - 1 or nil
  def previous_page_collection
    current_page > 1 ? page(current_page - 1, per_page) : nil
  end

  # current_page + 1 or nil if there is no next page
  #
  # will_paginate compatible
  def next_page
    current_page < total_pages ? (current_page + 1) : nil
  end

  # ActiveRecord::Collection for current_page + 1 or nil
  def next_page_collection
    current_page < total_pages ? page(current_page + 1, per_page) : nil
  end

  # Total number of entries across all pages, paginated or not.
  #
  # will_paginate compatible
  def total_entries
    @total_entries ||=
      if paginated? 
        if size < per_page and (current_page == 1 or size > 0)
          offset + length
        else
          load_total_count
        end
      else
        size
      end
  end

  # Total number of pages.
  #
  # will_paginate compatible.
  def total_pages
    @total_pages ||= (total_entries / per_page.to_f).ceil
  end

  # return a paginated version of this collection if it isn't already
  # returns self if already paginated
  def paginate
    paginated?? self : page(current_page || 1)
  end

  # forces pagination of self
  # returns 1 if the collection is now paginated
  # returns nil if already paginated
  def paginate!
    @current_page ? nil : @current_page = 1
  end

  # if the collection has a page parameter
  def paginated?
    current_page && current_page > 0
  end

  # true if the collection data has been loaded
  def loaded?
    !!@collection
  end

  protected

  # Pass methods on to the collection.
  def method_missing(method, *args)
    unless collection.respond_to?(method)
      message = "undefined method `#{method.to_s}' for \"#{collection}\":#{collection.class.to_s}"
      raise NoMethodError, message
    end
    
    if block_given?
      collection.send(method, *args)  { |*block_args| yield(*block_args) }
    else
      collection.send(method, *args)
    end
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

  # Find options for pagination.
  def paginated_options
    options = query_options
    if paginated?
      options[:offset] = offset
      options[:limit] = per_page
    end
    options
  end

  # Find options for count and collection.
  #
  # Loads in a user defined query options that can add whatever other options
  # that need to be passed to find.
  def find_options
    options = paginated_options
    options[:order] = @order if @order
    options[:include] = @includes if @includes
    options
  end

  # Count options are very similar to find_options. This method can be
  # overloaded to supply special count behavior, but be careful.
  #
  # Model.count with these options must return the same results as if you
  # were to call #size on the resulting collection. If there is a difference
  # in behavior, the ActiveRecord::Collection#size and #empty? methods will
  # behave inconsistently.
  def count_options
    paginated_options
  end

  def total_count_options
    query_options
  end

  # Overload this method to change the way the count is loaded.
  def load_count
    model_class.count(count_options)
  end

  def load_total_count
    model_class.count(total_count_options)
  end

  # Overload this method to change the way the collection is loaded.
  def load_collection
    model_class.all(find_options)
  end

  # The size of just this restricted collection.
  #
  # If this collection is paginated, it will usually equal the per_page number.
  #
  # The total_entries method returns the total number of records regardless of
  # pagination.
  def count
    @count ||= load_count
  end

  # The actual collection data. Must be memoized or you'll access data over
  # and over and over again.
  def collection
    @collection ||= load_collection
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
