module ActiveCollection
  module Pagination
    PER_PAGE = 30

    def self.included(mod)
      mod.extend ClassMethods

      mod.class_eval do
        alias_method_chain :total_entries, :pagination
        alias_method_chain :size, :pagination
        find_scope :pagination_options
      end
    end

    module ClassMethods
      def per_page
        PER_PAGE
      end
    end

    def current_page
      @current_page ||= params.has_key?(:page) ? (params[:page] || 1).to_i : nil
    end

    # Defaults to the model class' per_page.
    def per_page
      @per_page ||= params[:per_page] || (model_class.respond_to?(:per_page) && model_class.per_page) || self.class.per_page
    end
    attr_writer :per_page

    # Loads total entries and calculates the size from that.
    def size_with_pagination
      if paginated?
        if out_of_bounds?
          0
        elsif last_page?
          size_without_pagination % per_page
        else
          per_page
        end
      else
        size_without_pagination
      end
    end

    # Create a new collection for the page specified
    #
    # Optionally accepts a per page parameter which will override the default
    # per_page for the new collection (without changing the current collection).
    def page(pg, per = self.per_page)
      new_collection = self.class.new(params.merge(:page => pg))
      new_collection.per_page = per
      new_collection
    end

    # Force this collection to a page specified
    #
    # Optionally accepts a per page parameter which will override the per_page
    # for this collection.
    def page!(pg, per = self.per_page)
      raise_if_loaded
      @per_page = per
      @current_page = pg
    end

    # return a paginated collection if it isn't already paginated.
    # returns self if already paginated.
    def paginate
      paginated?? self : page(1)
    end

    # forces pagination of self, raising if already loaded.
    # returns current_page if the collection is now paginated
    # returns nil if already paginated
    def paginate!
      paginated?? nil : page!(1)
    end

    # Helper method that is true when someone tries to fetch a page with a
    # larger number than the last page. Can be used in combination with flashes
    # and redirecting.
    # 
    # loads total_entries if not already loaded.
    def out_of_bounds?
      current_page > total_pages
    end

    # Current offset of the paginated collection. If we're on the first page,
    # it is always 0. If we're on the 2nd page and there are 30 entries per page,
    # the offset is 30. This property is useful if you want to render ordinals
    # side by side with records in the view: simply start with offset + 1.
    # 
    # loads total_entries if not already loaded.
    def offset
      (current_page - 1) * per_page
    end

    # current_page - 1 or nil if there is no previous page.
    def previous_page
      current_page > 1 ? (current_page - 1) : nil
    end

    # current_page + 1 or nil if there is no next page.
    # 
    # loads total_entries if not already loaded.
    def next_page
      current_page < total_pages ? (current_page + 1) : nil
    end

    # true if the collection is the last page.
    # 
    # may load total_entries if not already loaded.
    def last_page?
      !out_of_bounds? && next_page.nil?
    end

    # New Collection for current_page - 1 or nil.
    def previous_page_collection
      previous_page ? page(previous_page, per_page) : nil
    end

    # New Collection for current_page + 1 or nil
    # 
    # loads total_entries if not already loaded.
    def next_page_collection
      next_page ? page(next_page, per_page) : nil
    end

    # Always returns the total count regardless of pagination.
    #
    # Attempts to save a count query if collection is loaded and is the last page.
    def total_entries_with_pagination
      @total_entries ||=
        if paginated? 
          if loaded? and length < per_page and (current_page == 1 or length > 0)
            offset + length
          else
            total_entries_without_pagination
          end
        else
          total_entries_without_pagination
        end
    end

    # Total number of pages.
    def total_pages
      (total_entries / per_page.to_f).ceil
    end

    # if the collection has a page parameter
    def paginated?
      current_page && current_page > 0
    end

    # TODO clean this up
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

    # TODO clean this up
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

    protected

    # Find options for pagination.
    def pagination_options
      { :offset => offset, :limit => per_page } if paginated?
    end

  end
end
