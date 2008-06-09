=begin rdoc
  A convenience method for working with plugins. 
  
  Sits on top of github.
=end
require "git"
module PoolParty
  class PluginManager
    include Callbacks
    
    before :new, :create_plugin_directory
    before :install, :create_plugin_directory
    
    # Create a new plugin in the directory specified here
    def self.new(location)
      FileUtils.mkdir_p plugin_directory(location)
      loc = Git.init(plugin_directory(location))
    end
    
    def self.install(location)
      
    end
    
    private
    
    def self.plugin_directory(path)
      File.join(base_plugin_dir, path)
    end
    def self.create_plugin_directory
      FileUtils.mkdir_p base_plugin_dir rescue ""
    end
    def self.base_plugin_dir
      File.join(PoolParty.root_dir, "plugins")
    end
  end
end