require "enumerator"
class Array
  def collect_with_index &block
    self.enum_for(:each_with_index).collect &block
  end
end