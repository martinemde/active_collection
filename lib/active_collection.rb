activesupport_path = "#{File.dirname(__FILE__)}/../../activesupport/lib"
$:.unshift(activesupport_path) if File.directory?(activesupport_path)
require 'active_support'

module ActiveCollection
  autoload :Base, 'active_collection/base'
  autoload :MemberClass, 'active_collection/member_class'
  autoload :Scope, 'active_collection/scope'
  autoload :Order, 'active_collection/order'
  autoload :Includes, 'active_collection/includes'
  autoload :Pagination, 'active_collection/pagination'
  autoload :Serialization, 'active_collection/serialization'

  Base
end

