=begin rdoc
  Os specific container
=end
module PoolParty
  module Os
  end
end

Dir["#{File.dirname(__FILE__)}/os/*"].each do |file|
  require file
end
