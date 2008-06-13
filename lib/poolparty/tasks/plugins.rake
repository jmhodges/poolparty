namespace(:plugins) do
  task :init do
    @command = ARGV.shift # Get rid of the command
    @name = (ENV['location'] || ENV["l"] || ARGV.shift)
    unless @name
      puts <<-EOM
Usage:
rake #{@command} location

Example:
rake #{@command} git://github.com/auser/pool-party-plugins.git

Check the help does for more information how to install a plugin
http://poolpartyrb.com
        
      EOM
      exit 
    end    
  end
  desc "Install a plugin from a git repository"
  task :install => :init do |command|
    PoolParty::PluginManager.install_plugin @name
  end
  desc "Remove an installed plugin"
  task :remove => :init do |command|
    PoolParty::PluginManager.remove_plugin @name
  end
  rule "" do |t|
  end
end