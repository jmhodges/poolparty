module PoolParty
  class Schema < Hash
    attr_reader :tree
    def initialize(h={})
      h.each {|k,v| self[k] = v}
    end
  end
end
class Hash
  def method_missing(sym, *args, &block)
    has_key?(sym) ? fetch(sym) : super
  end  
end