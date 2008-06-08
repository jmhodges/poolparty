# require "sprinkle"

Dir["#{File.dirname(__FILE__)}/packages/**"].each {|a| require a }

policy :pool_party, :roles => :app do
  requires :ruby
end
