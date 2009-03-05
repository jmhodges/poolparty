=begin rdoc
  Cloud extensions for the DependencyResolver
=end

module PoolParty
  # Take the cloud dependency tree
  module DependencyResolverCloudExtensions    
    def to_properties_hash
      {
        :options => options,
        :services => services.keys.map {|k| {k => services[k].to_properties_hash } },
        :resources => resources.keys.map {|k| {k => resources[k].map {|r| r.to_properties_hash } } }
      }
    end
    
  end
  
  # Adds the to_properties_hash method on top of resources, the lowest level
  module DependencyResolverResourceExtensions
    def to_properties_hash
      {
        :options => options
      }
    end
  end
end