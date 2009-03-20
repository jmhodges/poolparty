# =begin rdoc
#   This module is included by the remote module and defines the remoting methods
#   that the clouds can use to rsync or run remote commands
# =end
# 
# module PoolParty
#   module Remote
#     module Remoter      
#       # After launch callback
#       # This is called after a new instance is launched
#       def after_launched(force=false)        
#       end
#       
#       # Before shutdown callback
#       # This is called before the cloud is contracted
#       def before_shutdown
#       end
#             
#       def self.included(receiver)
#         receiver.extend self
#       end
#     end
#   end
# end
# 
# Dir["#{File.dirname(__FILE__)}/remoter/*.rb"].each do |base| 
#   require base
#   PoolParty::Remote::Remoter
# end
