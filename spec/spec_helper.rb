require File.dirname(__FILE__) + '/../lib/pool_party'

%w(test/spec ec2).each do |library|
  begin
    require library
  rescue
    STDERR.puts "== Cannot run test without #{library}"
  end
end

extend PoolParty

@config = YAML.load(File.read(Application.config_file))

AWS::S3::Base.establish_connection!(
:access_key_id     => @config[Application.env]["access_key_id"],
:secret_access_key => @config[Application.env]["secret_access_key"]
)

@ec2 = EC2::Base.new(:access_key_id => Organizer.access_key_id, :secret_access_key => Organizer.secret_access_key)

Organizer.options(:env => "test")

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