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

namespace(:pkg) do
  ## Rake task to create/update a .manifest file in your project, as well as update *.gemspec
  desc %{Update ".manifest" with the latest list of project filenames. Respect\
  .gitignore by excluding everything that git ignores. Update `files` and\
  `test_files` arrays in "*.gemspec" file if it's present.}
  task :manifest do
    list = Dir['**/*'].sort
    spec_file = Dir['*.gemspec'].first
    list -= [spec_file] if spec_file

    File.read('.gitignore').each_line do |glob|
      glob = glob.chomp.sub(/^\//, '')
      list -= Dir[glob]
      list -= Dir["#{glob}/**/*"] if File.directory?(glob) and !File.symlink?(glob)
      puts "excluding #{glob}"
    end

    if spec_file
      spec = File.read spec_file
      spec.gsub! /^(\s* s.(test_)?files \s* = \s* )( \[ [^\]]* \] | %w\( [^)]* \) )/mx do
        assignment = $1
        bunch = $2 ? list.grep(/^test\//) : list
        '%s%%w(%s)' % [assignment, bunch.join(' ')]
      end

      File.open(spec_file,   'w') {|f| f << spec }
    end
    File.open('Manifest', 'w') {|f| f << list.join("\n") }
  end
  desc "Build gemspec for github"
  task :gemspec => :manifest do
    require "yaml"
    `rake gem`
    data = YAML.load(open("poolparty.gemspec").read).to_ruby
    File.open("poolparty.gemspec", "w+") {|f| f << data }
  end
  desc "Update gemspec with the time"
  task :gemspec_update => :gemspec do
    data = open("poolparty.gemspec").read
    str = "Updated at #{Time.now.strftime("%I:%M%p, %D")}"
    
    if data.scan(/Updated at/).empty?
      data = data.gsub(/you just installed PoolParty\!/, '\0'+" (#{str})")
    end
    
    File.open("poolparty.gemspec", "w+") {|f| f << data }
  end
  desc "Release them gem to the gem server"
  task :release => :gemspec_update do
    `git add .`
    `git ci -a -m "Updated gemspec for github"`
    `git push gem`
  end
end