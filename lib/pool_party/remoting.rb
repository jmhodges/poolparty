module PoolParty
  extend self
  
  class Remoting
    def initialize(opts={})
      AWS::S3::Base.establish_connection!( :access_key_id => Organizer.access_key_id, :secret_access_key => Organizer.secret_access_key, :server => "#{Organizer.server_pool_bucket}.s3.amazonaws.com")
    end
  end
end