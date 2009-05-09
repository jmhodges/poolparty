class Symbol
  # def >(num);"#{self} > #{num}";end
  # def <(num);"#{self} < #{num}";end
  # def >=(num);"#{self} >= #{num}";end
  # def <=(num);"#{self} <= #{num}";end
  # def ==(num);"#{self} > #{num}";end
  
  def to_string(pre="")
    "#{pre}#{self.to_s}"
  end
  def sanitize
    self.to_s.sanitize
  end
  def <=>(b)
    "#{self}" <=> "#{b}"
  end
  ##
  # @param o<String, Symbol> The path component to join with the string.
  #
  # @return <String> The original path concatenated with o.
  #
  # @example
  #   :merb/"core_ext" #=> "merb/core_ext"
  def /(o)
    File.join(self.to_s, o.to_s)
  end
end