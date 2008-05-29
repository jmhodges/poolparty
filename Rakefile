require 'rubygems'
require 'echoe'
require 'lib/pool_party'

task :default => :test

Echoe.new("poolparty") do |p|
  p.author = "Ari Lerner"
  p.email = "ari.lerner@citrusbyte.com"
  p.summary = "Run your entire application off EC2, managed and auto-scaling"
  p.url = "http://blog.citrusbyte.com"
  p.docs_host = "www.poolpartyrb.com"
  p.dependencies = %w(aws-s3 amazon-ec2 aska)
  p.install_message = "For more information, check http://poolpartyrb.com\n*** Ari Lerner @ <ari.lerner@citrusbyte.com> ***"
  p.include_rakefile = true
end

PoolParty::Tasks.new
