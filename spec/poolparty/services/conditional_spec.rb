require File.dirname(__FILE__) + '/../spec_helper'

describe "Conditional" do
  it "not fail when calling case_of" do
    case_of "b"
    end_of
  end
  it "should put the case object on the case stack as a Conditional object" do
    case_of "b"
    end_of
    working_conditional.last.attribute.should == "b"
  end
  it "should populate the when_statements when a when_is is called" do
    case_of "b"
    when_is "b"
    end_of
    working_conditional.last.when_statements.size.should == 1
  end
  it "freeze the case statement when calling end_of" do
    case_of "b"
    when_is "b" do
    end
    end_of
    working_conditional.last.options.frozen?.should == true
  end
  it "create a new service for the when_is block" do
    case_of "b"
    when_is "b" do
      "I'm TOTALLY B!"
    end
    end_of
    working_conditional.last.when_statements[0][1].is_a?(Service).should == true
  end
  it "create a new service for the when_is block" do
    case_of "b"
    when_is "b" do
      "I'm TOTALLY B!"
    end
    when_is "c" do
      "You are not 'c', don't lie!"
    end
    end_of
    working_conditional.last.when_statements[0][1].is_a?(Service).should == true
  end
end