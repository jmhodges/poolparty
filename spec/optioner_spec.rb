require File.dirname(__FILE__) + '/spec_helper'

describe "Optioner with options" do
  it "should be able to pull out the lonely arguments without any switches" do
    Optioner.parse("hello".split(" ")).should == ["hello"]
  end
  it "should be able to pull out the lonely arguments with switches" do
    Optioner.parse("-s 30.seconds -m hello world".split(" ")).should == ["world"]
  end
  it "should be able to pull out start from the the string" do
    Optioner.parse("-c 'config/config.yml' -A 'Who' -S 'DarkwingDuck' list".split(" ")).should == ["list"]
  end
  it "should be able to pull out the lonely arguments with optional argument switches" do
    Optioner.parse("-s 30 -q -n start".split(" "), %w(-q -n)).should == ["start"]
  end
  it "should pull out the lonely arguments if none are there" do
    Optioner.parse("-s 30 -q".split(" ")).should == []
  end
  it "should pull out empty array if there are no lonely arguments" do
    Optioner.parse("-s 30".split(" ")).should == []
  end
end