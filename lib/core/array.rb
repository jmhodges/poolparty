=begin rdoc
  Array extensions
=end
require "enumerator"
class Array
  # Collection with the index
  def collect_with_index &block
    self.enum_for(:each_with_index).collect &block
  end
end