namespace(:pkg) do
  desc "Build gemspec for github"
  task :gemspec do
    require "yaml"
    `rake manifest gem`
    data = YAML.load(open("poolparty.gemspec").read).to_ruby
    File.open("poolparty.gemspec", "w+") {|f| f << data }
  end
  desc "Update gemspec with the time"
  task :gemspec_update do
    data = data = open("poolparty.gemspec").read
    str = "Updated at #{Time.now.strftime("%I:%M%p, %D")}"

    data = data.gsub(/you just installed PoolParty!/, '\0'+" (#{str})")
    
    File.open("poolparty.gemspec", "w+") {|f| f << data }
  end
  desc "Release them gem to the gem server"
  task :release => :gemspec_update do
    `git push gem`
  end
end