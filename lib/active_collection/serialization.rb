module ActiveCollection
  module Serialization
    # Turn the params into a hash suitable such that passing the collection
    # directly to a named path generates the path for the current collection.
    def to_param
      params.empty?? nil : params.to_param
    end

    def as_data_hash
      data_hash = { table_name => collection.as_json }
      data_hash["total_entries"] = total_entries
      data_hash
    end

    def to_xml(options = {})
      collect
      options[:indent] ||= 2
      xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
      xml.instruct! unless options[:skip_instruct]
      xml.collection do
        xml.total_entries(total_entries, :type => "integer")
        xml.tag!(table_name, :type => "array") do
          collection.each do |item|
            item.to_xml(:indent => options[:indent], :builder => xml, :skip_instruct => true)
          end
        end
      end
    end

    def as_json(options = nil)
      {"collection" => as_data_hash}.as_json(options)
    end
  end
end
