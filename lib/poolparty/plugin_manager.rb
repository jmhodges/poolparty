=begin rdoc
  A convenience method for working with plugins. 
  
  Sits on top of github.
=end
require "git"
module PoolParty
  def installed_plugins
    @@installed_plugins ||= []
  end  
  class PluginManager
    include Callbacks
    
    before :new, :create_plugin_directory
    before :install, :create_plugin_directory
    
    # Create a new plugin in the directory specified here
    def self.new_plugin(location)
      FileUtils.mkdir_p plugin_directory(location)      
      begin
        Git.open(plugin_directory(location))
      rescue Exception => e
        Git.init(plugin_directory(location))
        Git.open(plugin_directory(location))
      end
    end
    
    def self.install_plugin(location)
      Git.clone(location, plugin_directory(location))
    end
    
    def self.scan
      reset!
      returning installed_plugins do
        Dir["#{Application.root_dir}/plugins/*"].each do |plugin|
          installed_plugins << [File.basename(plugin)]
        end
      end
    end
    
    private
    
    def self.plugin_directory(path)
      File.join(base_plugin_dir, File.basename(path, File.extname(path)))
    end
    def self.create_plugin_directory
      FileUtils.mkdir_p base_plugin_dir rescue ""
    end
    def self.base_plugin_dir
      File.join(PoolParty.root_dir, "plugins")
    end
  end
end