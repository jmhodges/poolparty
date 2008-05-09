module PoolParty
  class LocalInstance
        
    # Load the configuration parameters from the user-data when launched
    def config
      @config ||= YAML.load(URI.parse("http://169.254.169.254/latest/user-data"))
    end
    
  end
end