=begin rdoc
  Load the files in order
=end
%w(application scheduler remoting os remote_instance master tasks).each {|f| require File.join(File.dirname(__FILE__), f)}