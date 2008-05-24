=begin rdoc
  The main file, contains the client and the server application methods
=end
$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# rubygems
require 'rubygems'
require "aws/s3"
require "sqs"
require "EC2"
require "rack"
require 'thread'
require "pp"
require "tempfile"
begin
  require 'fastthread'
  require 'thin'
rescue LoadError
end

## Load PoolParty
pwd = File.dirname(__FILE__)

%w(core modules s3 pool_party).each do |dir|  
  Dir["#{pwd}/#{dir}"].each do |dir|
    begin
      require File.join(dir, "init")
    rescue LoadError => e
      Dir["#{pwd}/#{File.basename(dir)}/**"].each {|file| require File.join(dir, File.basename(file))}
    end
  end
end

module PoolParty  
  module Version
    MAJOR = '0'
    MINOR = '0'
    REVISION = '3'
    def self.combined
      [MAJOR, MINOR, REVISION].join('.')
    end
  end

  def options(opts={})
    Application.options(opts)
  end
  def verbose?
    Application.verbose == true
  end
  def message(msg="")
    pp "-- #{msg}" if verbose?
  end
  def root_dir
    File.dirname(__FILE__)
  end
  def write_to_temp_file(str)
    tempfile = Tempfile.new("rand#{rand(1000)}-#{rand(1000)}")
    tempfile.print(str)
    tempfile.flush
    tempfile
  end
end