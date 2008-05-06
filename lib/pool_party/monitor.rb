module PoolParty
  extend self
  
  module Monitors
    
    class Monitor
      attr_accessor :maximum, :minimum
      
      def initialize(min, max)
        @minimum = min
        @maximum = max
      end
      # Monitor on specific monitors
      def monitor!
      end
    end
    
  end
  
end

Dir["#{File.dirname(__FILE__)}/monitors/*"].each do |file|
  require file
end
