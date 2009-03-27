module PoolParty
  class Schema < Hash
    def initialize(h={})
      case h
      when Hash
        h.each {|k,v| self[k] = v}
      when String
        JSON.parse(h).each {|k,v| self[k.to_sym] = v}
      end      
    end
    def save!
      ::File.open("#{Default.base_config_directory}/#{Default.properties_hash_filename}", "w") {|f| f << self.to_json }
    end
  end
end
class Hash
  def [](key)
    if has_key?(key)
      fetch(key)
    elsif has_key?(key.to_s)
      fetch(key.to_s)
    else
      nil
    end
  end
  def method_missing(sym, *args, &block)
    if has_key?(sym.to_sym)
      fetch(sym)
    elsif has_key?(sym.to_s)
      fetch(sym.to_s)
    else
      super
    end
  end  
end