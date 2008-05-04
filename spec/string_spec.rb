require File.dirname(__FILE__) + '/spec_helper'

describe "String" do
  before(:each) do
    @string = "string"
    @string.stub!(:bucket_objects).and_return([])
  end
  # Dumb test
  it "should be able to call bucket_objects on itself" do
    @string.should_receive(:bucket_objects)
    @string.bucket_objects
  end
end