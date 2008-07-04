=begin rdoc
  The main file, contains the client and the server application methods
=end
$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

$TRACE = true

# rubygems
require 'rubygems'
require "aws/s3"
require "EC2"
require "aska"
require 'sprinkle'
require "pp"
require "tempfile"

begin
  require 'fastthread'
  require 'system_timer'
  @@timer = SystemTimer
rescue LoadError
  require 'thread'
  require 'timeout'
  @@timer = Timeout
end

## Load PoolParty
pwd = File.dirname(__FILE__)

# Load the required files
# If there is an init file, load that, otherwise
# require all the files in each directory
%w(core modules s3 helpers poolparty).each do |dir|  
  Dir["#{pwd}/#{dir}"].each do |dir|
    begin
      require File.join(dir, "init")
    rescue LoadError => e
      Dir["#{pwd}/#{File.basename(dir)}/**"].each {|file| require File.join(dir, File.basename(file))}
    end
  end
end

module PoolParty
  class Version #:nodoc:
    @major = 0
    @minor = 1
    @tiny  = 0

    def self.string
      [@major, @minor, @tiny].join('.')
    end
  end
  def timer
    @@timer
  end
  # PoolParty options
  def options(opts={})
    Application.options(opts)
  end
  # Are we working in verbose-mode
  def verbose?
    options.verbose == true
  end
  # Send a message if we are in verbose-mode
  def message(msg="")
    puts "-- #{msg}" if verbose?
  end
  # Root directory of the application
  def root_dir
    File.expand_path(File.dirname(__FILE__) + "/..")
  end
  # User directory
  def user_dir
    Application.working_directory
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
      unless registered_monitor?(name)
        PoolParty::Monitors.extend name
      
        PoolParty::Master.send :include, name::Master
        PoolParty::RemoteInstance.send :include, name::Remote
        
        registered_monitors << name
      end
    end
  end
  def registered_monitor?(name); registered_monitors.include?(name); end
  def registered_monitors; @@registered_monitors ||= [];end
  
  def load_app
    load_monitors
    load_plugins
  end  
  def load_monitors
    loc = File.directory?("#{user_dir}/monitors") ? "#{user_dir}/monitors" : "#{root_dir}/lib/poolparty/monitors"
    Dir["#{loc}/*"].each {|f| require f}
  end
  
  def load_plugins
    Dir["#{plugin_dir}/**/init.rb"].each {|a| require a} if File.directory?(plugin_dir)
  end
  def reset!
    @@registered_monitors = nil
    @@installed_plugins = nil
  end
  def plugin_dir
    "#{user_dir}/plugins"
  end
  def read_config_file(filename)
    return {} unless filename
    YAML.load(open(filename).read)
  end
  def include_cloud_tasks
    Tasks.new.define_tasks
  end
  
  alias_method :tasks, :include_cloud_tasks
  alias_method :include_tasks, :include_cloud_tasks
end