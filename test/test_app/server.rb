require "rubygems"
require "sinatra"
require "pool_party"

PoolParty.client("config/config.yml", :env => Sinatra.env)

get '/' do
  haml :home
end

get '/site.css' do
  header 'Content-Type' => 'text/css; charset=utf-8'
  sass :site
end
