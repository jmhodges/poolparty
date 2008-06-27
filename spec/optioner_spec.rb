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
  it "should be able to pull out the lonely arguments with optional argument switches in any order" do
    Optioner.parse("start -s 30 -q -n".split(" "), %w(-q -n)).should == ["start"]
  end
  it "should be able to pull out the lonely, default arguments with optional argument switches" do
    Optioner.parse("-s 30 -q -n start -i -v".split(" "), %w(-q -n)).should == ["start"]
  end
  it "should pull out the lonely arguments if none are there" do
    Optioner.parse("-s 30 -q".split(" ")).should == []
  end
  it "should pull out empty array if there are no lonely arguments" do
    Optioner.parse("-s 30".split(" ")).should == []
  end
  it "should pull out quoted arguments" do
    Optioner.parse("-s 30 'ls'".split(" ")).should == ["'ls'"]
  end
  it "should be able to pull out a quoted argument in a sea of nonquotes" do
    Optioner.parse("-v -k auser scp 'pkg/poolparty-0.0.9.gem'".split(" ")).should == ["scp", "'pkg/poolparty-0.0.9.gem'"]
  end
end