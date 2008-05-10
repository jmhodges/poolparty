require File.join(File.dirname(__FILE__), *%w[.. lib pool_party])

%w(test/spec).each do |library|
  begin
    require library
  rescue
    STDERR.puts "== Cannot run test without #{library}"
  end
end

include PoolParty
extend PoolParty

Application.environment = "test"

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