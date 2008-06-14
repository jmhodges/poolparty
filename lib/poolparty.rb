=begin rdoc
  The main file, contains the client and the server application methods
=end
$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# rubygems
require 'rubygems'
require "aws/s3"
require "sqs"
require "EC2"
require 'thread'
require "pp"
require "tempfile"
require "aska"
begin
  require 'fastthread'
  require 'thin'
rescue LoadError
end

## Load PoolParty
pwd = File.dirname(__FILE__)

# Load the required files
# If there is an init file, load that, otherwise
# require all the files in each directory
%w(core modules s3 poolparty).each do |dir|  
  Dir["#{pwd}/#{dir}"].each do |dir|
    begin
      require File.join(dir, "init")
    rescue LoadError => e
      Dir["#{pwd}/#{File.basename(dir)}/**"].each {|file| require File.join(dir, File.basename(file))}
    end
  end
end

module PoolParty
  # PoolParty options
  def options(opts={})
    Application.options(opts)
  end
  # Are we working in verbose-mode
  def verbose?
    Application.verbose == true
  end
  # Send a message if we are in verbose-mode
  def message(msg="")
    pp "-- #{msg}" if verbose?
  end
  # Root directory of the application
  def root_dir
    File.join(File.dirname(__FILE__), "..")
  end
  # Write string to a tempfile
  def write_to_temp_file(str="")
    tempfile = Tempfile.new("rand#{rand(1000)}-#{rand(1000)}")
    tempfile.print(str)
    tempfile.flush
    tempfile
  end
  def register_monitor(*names)
    names.each do |name|
      PoolParty::Monitors.extend name
      
      PoolParty::Master.send :include, name::Master
      PoolParty::RemoteInstance.send :include, name::Remote
    end
  end
  def load_plugins
    Dir["#{PluginManager.base_plugin_dir}/**/init.rb"].each {|a| require a}
  end
  def reset!
    @@installed_plugins = nil
  end
  def include_cloud_tasks
    Tasks.new.define_tasks
  end
  
  alias_method :tasks, :include_cloud_tasks
  alias_method :include_tasks, :include_cloud_tasks
end