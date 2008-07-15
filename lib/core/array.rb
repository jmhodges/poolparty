=begin rdoc
  Array extensions
=end
require "enumerator"
class Array
  # Collection with the index
  def collect_with_index &block
    self.enum_for(:each_with_index).collect &block
  end
  def runnable(quiet=true)
    self.join(" \n ").runnable(quiet)
  end
  def nice_runnable(quiet=true)
    self.join(" \n ").nice_runnable(quiet)
  end
end