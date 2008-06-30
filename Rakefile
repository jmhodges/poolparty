require 'rubygems'
require "lib/poolparty"
begin
  require 'echoe'
  
  Echoe.new("poolparty") do |s|
    s.author = "Ari Lerner"
    s.email = "ari.lerner@citrusbyte.com"
    s.summary = "Run your entire application off EC2, managed and auto-scaling"
    s.url = "http://blog.citrusbyte.com"
    s.dependencies = ["aws-s3", "amazon-ec2", "auser-aska", "git", "crafterm-sprinkle", "SystemTimer"]
    s.install_message = %q{
      
      Get ready to jump in the pool, you just installed PoolParty!

      Please check out the documentation for any questions or check out the google groups at
        http://groups.google.com/group/poolpartyrb

      Don't forget to check out the plugin tutorial @ http://poolpartyrb.com for extending PoolParty!      

      For more information, check http://poolpartyrb.com
      On IRC: 
        irc.freenode.net
        #poolpartyrb
      *** Ari Lerner @ <ari.lerner@citrusbyte.com> ***
    }
  end
  
rescue LoadError => boom
  puts "You are missing a dependency required for meta-operations on this gem."
end

task :default => :test

PoolParty.include_tasks