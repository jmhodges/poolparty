require File.join(File.dirname(__FILE__), *%w[.. lib poolparty])

%w(test/spec).each do |library|
  begin
    require library
  rescue
    STDERR.puts "== Cannot run test without #{library}"
  end
end

Dir["#{File.dirname(__FILE__)}/helpers/**"].each {|a| require a}

include PoolParty
extend PoolParty

Application.environment = "test"
Application.verbose = false

def wait_launch(time=5)
  pid = fork {yield}
  wait time
  Process.kill("INT", pid)
  Process.wait(pid, 0)
end

module Test::Unit::AssertDifference
  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end

  def assert_no_difference(object, method, &block)
    assert_difference object, method, 0, &block
  end
end

Test::Spec::Should.send(:include, Test::Unit::AssertDifference)
Test::Spec::ShouldNot.send(:include, Test::Unit::AssertDifference)