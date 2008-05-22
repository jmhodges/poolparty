require "rubygems"
require "sinatra"

get '/' do
  haml :home
end

get '/site.css' do
  header 'Content-Type' => 'text/css; charset=utf-8'
  sass :site
end
