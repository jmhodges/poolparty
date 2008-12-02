require "rubygems"
require "treetop"

%w(numbers strings keywords base pool cloud allowedtypes primatives).each do |f|
  Treetop.load "#{File.dirname(__FILE__)}/grammars/PP#{f}"
end

%w(preparser parser).each do |f|
  require "#{File.dirname(__FILE__)}/lib/#{f}"
end

parser = PoolParser.new
puts parser.parse(<<-EOE
  pool name do
    using ec2
  end
EOE
).inspect