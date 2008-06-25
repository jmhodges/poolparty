require File.dirname(__FILE__) + '/spec_helper'

describe "Hash" do
  it "should preserve the contents of the original hash when safe_merge'ing" do
    a = {:a => "10", :b => "20"}
    b = {:b => "30", :c => "40"}
    a.safe_merge(b).should == {:a => "10", :b => "20", :c => "40"}
  end
  it "should preserve the contents of the original hash when safe_merge!'ing" do
    a = {:a => "10", :b => "20"}
    b = {:b => "30", :c => "40"}
    a.safe_merge!(b)
    a.should == {:a => "10", :b => "20", :c => "40"}
  end
end
describe "String" do
  it "should be able to convert a big string with \n to a runnable string" do
    str =<<-EOS
      echo 'hi'
      puts 'hi'
    EOS
    str.runnable.should == "echo 'hi' &&       puts 'hi'"
  end
end