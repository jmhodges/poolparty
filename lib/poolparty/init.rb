=begin rdoc
  Load the files in order
=end
%w(optioner application monitors scheduler remoting remoter remote_instance master tasks plugin plugin_manager).each do |f|
  require File.join(File.dirname(__FILE__), f)
end