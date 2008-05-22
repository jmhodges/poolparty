require 'rubygems'
require 'echoe'
require 'lib/pool_party'

task :default => :test

Echoe.new("pool_party") do |p|
  p.author = "Ari Lerner"
  p.summary = "Run your entire application off EC2, managed and auto-scaling"
  p.url = "http://blog.citrusbyte.com"
  p.docs_host = "www.poolpartyrb.com"
  p.dependencies = %w(aws-s3 EC2 sqs rack)
  p.install_message = "*** Ari Lerner @ <ari.lerner@citrusbyte.com>\nNicolás Sanguinetti <nicolas.sanguinetti@citrusbyte.com> ***"
  p.include_rakefile = true
end

PoolParty::Tasks.new
