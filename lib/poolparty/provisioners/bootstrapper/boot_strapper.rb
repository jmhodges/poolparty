require 'rubygems'
require 'open4'
require 'ec2'

#provide a very simple provisioner with as few dependencies as possible
module BootStrap
  class Ec2
    aws_keys = {}
    aws_keys = YAML::load( File.open('/etc/poolparty/aws_keys.yml') ) rescue 'No aws_keys.yml file.   Will try to use enviornment variables'
    ACCESS_KEY_ID = aws_keys[:access_key] || ENV['AMAZON_ACCESS_KEY_ID'] || ENV['AWS_ACCESS_KEY']
    SECRET_ACCESS_KEY = aws_keys[:secret_access_key] || ENV['AMAZON_SECRET_ACCESS_KEY'] || ENV['AWS_SECRET_ACCESS_KEY']
  
    def ec2
      # default server is US ec2.amazonaws.com
      @ec2 ||= EC2::Base.new( :access_key_id => ACCESS_KEY_ID, :secret_access_key => SECRET_ACCESS_KEY )
    end
  
    # Return a list of public dns names of running instances
    def instances( conditions = {:instanceState=>'running'} )
      ec2.describe_instances.reservationSet.item.first.instancesSet.item.collect do |instance|
         instance.dnsName if instance.instanceState.name == conditions[:instanceState]
      end.compact
    end
  end
 
 
  module CommandRunner
    def ec2
      @ec2 ||= Ec2.new
    end
  
    def target_host(dns_or_ip=nil)
      dns_or_ip ? @target_host=dns_or_ip : @target_host
    end
  
    def run_remote(command, host=target_host, options=[])
      command = command.join(' && ') if command.is_a? Array
      cmd = "ssh #{host} #{options.join(' ')} '#{command}'"
      puts "running_remote: #{cmd}\n"
      puts %x{#{cmd}}
      # require 'rubygems'; require 'ruby-debug'; debugger
    end
  
    def rsync( source_path, destination_path, options=['--progress'] )
      puts %x{ rsync #{options.join(' ')} #{source_path}  #{destination_path} }
    end
   
     def run_local(commands)
       commands.each do |cmd|
         puts `#{cmd}`
       end
     end
  end
 
 
  class BootStraper
    include CommandRunner
  
    @defaults = {
      :user                  => "root",
      :keypair_file          => kp ="#{ENV["AWS_KEYPAIR_NAME"]}" || "~/.ssh/id_rsa",
      :keypair               => File.basename(kp),
      :tmp_path              => "/tmp/poolparty",
      :poolparty_home_path   => "#{ENV["HOME"]}/.poolparty",
      :remote_storage_path   => "/var/poolparty",
      :remote_gem_path       => "/var/poolparty/gems",
      :base_config_directory => "/etc/poolparty",
      :default_specfile_name => "clouds.rb",
      :ami                   => "ami-7cfd1a15",
      :instance_size         => 'm1.small',
      :distro                => 'ubuntu',
      :installer             => 'apt-get install -y',
      :dependency_resolver   => 'puppet',
      :dependencies_tarball  => ''
    }
    class <<self; attr_reader :defaults; end
  
    def initialize(host, opts={}, &block)
      self.class.defaults.merge(opts).each do |k,v| 
        instance_variable_set "@#{k}", v
        self.class.send :attr_reader, k
      end
      @target_host = host
      @commands = []
    
      instance_eval &block
    end
  
    def commands
      @commands
    end
  
    def execute
      commands.each {|c| run_remote(c, @target_host, ssh_options) }
    end
  
    def ssh_options(ops=[""])
      ["-i #{keypair_file} -l #{user}"]
    end
  end
 
 
  #======
 
  host = Ec2.new.instances.shift
  
  server = BootStraper.new(host, {:keypair_file => '/Users/mfairchild/.ec2oncourse/r_and_d.pem'}) do
    if host.nil? || host.empty?
       # ec2.run_instance
      loop do
        sleep 2
        host = ec2.instances.first
        next if host and !host.empty?
      end
    end
    
    puts "Provisioning #{host}"
    
    # base_tasks
    commands << prepare_host = [
      "mkdir -p /etc/poolparty",
      "mkdir -p /mnt/poolparty",
      "#{installer} ruby",
      "#{installer} ruby1.8-dev libopenssl-ruby1.8 ruby1.8-dev build-essential wget",  #optional, but nice to have
      "#{installer} #{dependency_resolver}"
      ]
 
    commands << install_rubygems = [
      "wget http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz",
      "tar -zxvf rubygems-1.3.1.tgz",
      "cd rubygems-1.3.1",
      "ruby setup.rb",
      "ln -sfv /usr/bin/gem1.8 /usr/bin/gem"
      ]
 
    commands << install_gems = [
     "cd /mnt/poolparty/",
     # "tar -zxvf #{dependencies_tarball}",
     # "cd #{dependencies_tarball.gsub(/\.tgz/,'')}",
     "gem install -y *.gem"]   
 
    # chef solo install
    commands << install_chef = [
      # 'gem sources -a http://gems.opscode.com',
      'gem install chef ohai rake -s http://gems.opscode.com']
  
    commands << ['touch /tmp/testfile']
  
    # commands << ["add neighborhood.json"]
 
    # run_local ["scp -i #{keypair} -l root #{dependencies_tarball} #{target_host}:/etc/poolparty/"]
  end
 
  server.execute
end