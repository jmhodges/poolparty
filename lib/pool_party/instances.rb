module PoolParty
  module Instances
  end
end

Dir["#{File.dirname(__FILE__)}/instances/*"].each do |file|
  require file
end
