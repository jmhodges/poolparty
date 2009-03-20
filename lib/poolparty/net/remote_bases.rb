require File.dirname(__FILE__) + "/remoter_base"

Dir["#{File.dirname(__FILE__)}/remote_bases/*.rb"].each do |base| 
  name = ::File.basename(base, ::File.extname(base))
  require base
  register_remote_base name
end