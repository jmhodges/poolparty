include_recipe "git-deploy"
include_recipe "apache2"
include_recipe "passenger"

deploy "/var/www/poolparty-website" do
  repo "git://github.com/auser/poolparty-website.git"
  branch "HEAD"
  enable_submodules true
  shallow_clone true
  action :manage
end