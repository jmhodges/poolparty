require File.dirname(__FILE__) + '/helper'

context "when retrieving" do
  setup do
    @session = Rack::Session::Cookie.new Object.new
    
    @incrementor = lambda { |env|
      Rack::Response.new(env["rack.session"].inspect).to_a
    }
    
  end
  specify "should be able to load a cookie from the bucket" do
    res = Rack::MockRequest.new(Rack::Session::Cookie.new(@incrementor)).get("/")
  end
  specify "should be able to fetch the objects in the s3 cookie bucket" do
    Remoter.cookie_bucket_objects.size.should_not == 0
  end
end