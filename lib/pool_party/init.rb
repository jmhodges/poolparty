=begin rdoc
  Load the files in order
=end
%w(optioner application monitors scheduler remoting os remote_instance master tasks plugin).each {|f| require File.join(File.dirname(__FILE__), f)}