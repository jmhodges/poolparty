=begin rdoc
  Basic monitors for the master
=end
module PoolParty  
  module Monitors    
    class Monitor
    end    
  end  
end

Dir["#{File.dirname(__FILE__)}/monitors/*"].each do |file|
  require file
end
