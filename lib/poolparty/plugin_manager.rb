=begin rdoc
  A convenience method for working with plugins. 
  
  Sits on top of github.
=end
require "git"
module PoolParty
  def installed_plugins
    @@installed_plugins ||= PluginManager.extract_git_repos_from_plugin_dirs.uniq
  end
  class PluginManager
    include Callbacks
            
    def self.install_plugin(location)
      unless File.directory?(plugin_directory(location))
        begin
          Git.clone(location, plugin_directory(location))      
          reset!
        rescue Exception => e
          puts "There was an error"
          puts e
        end
      else
        puts "Plugin already installed"
      end
    end
    
    def self.remove_plugin(name)
      Dir["#{PoolParty.root_dir}/#{PoolParty.plugin_dir}/*"].select {|a| a =~ /#{name}/}.each do |dir|
        FileUtils.rm_rf dir
      end
    end
    
    def self.scan
      returning Array.new do |a|
        plugin_dirs.each do |plugin|
          a << File.basename(plugin)
        end
      end
    end
    
    def self.extract_git_repos_from_plugin_dirs
      returning [] do |arr|
        plugin_dirs.each do |dir|
          arr << open(File.join(dir, ".git", "config")).read[/url[\s]*=[\s](.*)/,1]
        end
      end
    end
    
    def self.plugin_dirs
      Dir["#{PoolParty.root_dir}/vendor/*"]
    end
        
    def self.plugin_directory(path)
      File.join(base_plugin_dir, File.basename(path, File.extname(path)))
    end
    def self.create_plugin_directory
      FileUtils.mkdir_p base_plugin_dir rescue ""
    end
    def self.base_plugin_dir
      File.join(PoolParty.root_dir, "vendor")
    end
  end
end