=begin rdoc
  The main file, contains the client and the server application methods
=end
$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# rubygems
require 'rubygems'
require "aws/s3"
require "sqs"
require "EC2"
require "aska"
require 'sprinkle'

require 'thread'
require "pp"
require "tempfile"

begin
  require 'fastthread'
  require 'system_timer'
  Timer = SystemTimer  
rescue LoadError
  require 'timeout'
  Timer = Timeout
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
  module Version #:nodoc:
    MAJOR = 0
    MINOR = 0
    TINY  = 8

    STRING = [MAJOR, MINOR, TINY].join('.')
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
    Dir.pwd
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
    Dir["#{plugin_dir}/**/init.rb"].each {|a| require a}
  end
  def reset!
    @@installed_plugins = nil
    Application.options = nil
  end
  def plugin_dir
    "#{user_dir}/vendor"
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