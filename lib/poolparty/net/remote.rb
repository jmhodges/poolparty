require File.dirname(__FILE__) + "/remoter"

class Object
  def remote_bases
    $remote_bases ||= []
  end
  # Register the remoter base in the remote_bases global store
  def register_remote_base(*args)
    args.each do |arg|
      base_name = "#{arg}".downcase.to_sym
      (remote_bases << base_name) unless remote_bases.include?(base_name)
    end
  end
  alias :available_bases :remote_bases
end

module PoolParty
  module Remote
  end
end

require File.dirname(__FILE__) + "/remoter_base"