namespace(:pkg) do
  desc "Build gemspec for github"
  task :gemspec do
    require "yaml"
    `rake manifest gem`
    data = YAML.load(open("poolparty.gemspec").read).to_ruby
    File.open("poolparty.gemspec", "w+") {|f| f << data }
  end
end