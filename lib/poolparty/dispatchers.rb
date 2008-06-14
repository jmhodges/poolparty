=begin rdoc
  Basic monitors for the master
=end
module PoolParty
  class Dispatchers
  end
end

Dir["dispatchers/*"].each {|f| require f}