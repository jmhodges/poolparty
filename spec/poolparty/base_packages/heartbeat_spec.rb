require File.dirname(__FILE__) + '/../spec_helper'

describe "heartbeat base package" do
  it "should have the heartbeat package defined" do
    lambda {PoolpartyBaseHeartbeatClass}.should !raise_error
  end
end