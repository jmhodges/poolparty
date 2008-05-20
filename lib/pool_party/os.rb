module PoolParty
  def exec_remote(ri,opts={})
    hash = {
      :cmd => "scp", 
      :src => "None",
      :dest => "None",
      :switches => "",
      :user => "root",
      :silent => verbose?,
      :cred => Application.credentials}.merge(opts)
    
    hash[:switches] += "-i #{hash[:cred]}"    
    # cmd = hash[:cmd].strip.gsub(/^\"(\n)^\"/, " && ")
    cmd = hash[:cmd]

    f = case hash[:cmd]
      when "scp"
        "scp #{hash[:switches]} #{hash[:src]} #{hash[:user]}@#{ri.ip}:#{hash[:dest]}"
      else
        "ssh #{hash[:switches]} #{hash[:user]}@#{ri.ip} '#{cmd}'"
      end
    
    message("executing #{f}")
    [system(f), f]
  end
  module Os
  end
end

Dir["#{File.dirname(__FILE__)}/os/*"].each do |file|
  require file
end
