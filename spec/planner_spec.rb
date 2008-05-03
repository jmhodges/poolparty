require File.dirname(__FILE__) + '/helper'

context "with config" do
  specify "should have the access_key_id accessible on the class level" do
    Planner.access_key_id.should_not be_nil
  end
  specify "should have the secret_access_key accessible on the class" do
    Planner.secret_access_key.should_not be_nil
  end
  specify "should have the server_pool_bucket accessible on the class" do
    Planner.server_pool_bucket.should_not be_nil
  end
  specify "should have the ami method accessible on the class" do
    Planner.ami.should_not be_nil
  end
end