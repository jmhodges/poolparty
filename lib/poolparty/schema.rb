class Hash
  def method_missing(sym, *args, &block)
    has_key?(sym) ? fetch(sym) : super
  end  
end