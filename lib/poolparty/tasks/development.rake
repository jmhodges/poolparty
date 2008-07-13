namespace(:dev) do
  task :init do
    setup_application
    run "mkdir ~/.ec2 >/dev/null 2>/dev/null" unless File.directory?("~/.ec2")      
  end
  # Setup a basic development environment for the user 
  desc "Setup development environment specify the config_file"
  task :setup => [:init] do
    keyfilename = ".#{Application.keypair}_pool_keys"
    run <<-EOR
      echo 'export AWS_ACCESS_KEY=\"#{Application.access_key}\"' > $HOME/#{keyfilename}
      echo 'export AWS_SECRET_ACCESS=\"#{Application.secret_access_key}\"' >> $HOME/#{keyfilename}
      echo 'export EC2_HOME=\"#{Application.ec2_dir}\"' >> $HOME/#{keyfilename}
      echo 'export KEYPAIR_NAME=\"#{Application.keypair}\"' >> $HOME/#{keyfilename}
      echo 'export CONFIG_FILE=\"#{Application.config_file}\"' >> $HOME/#{keyfilename}
      echo 'export EC2_PRIVATE_KEY=`ls ~/.ec2/#{Application.keypair}/pk-*.pem`;' >> $HOME/#{keyfilename}
      echo 'export EC2_CERT=`ls ~/.ec2/#{Application.keypair}/cert-*.pem`;' >> $HOME/#{keyfilename}
      source $HOME/#{keyfilename}
    EOR
  end
  desc "Generate a new keypair"
  task :setup_keypair => :init do
    unless File.file?(Application.keypair_path)
      Application.keypair ||= "cloud"
      puts "-- setting up keypair named #{Application.keypair}"
      run <<-EOR
        ec2-add-keypair #{Application.keypair} > #{Application.keypair_path}
        chmod 600 #{Application.keypair_path}
      EOR
    end
  end
  desc "Just an argv test"
  task :test => :init do
    puts "---- Testing ----"
    puts PoolParty.options(ARGV.dup)
  end
  desc "Authorize base ports for application"
  task :authorize_ports => :init do
    run <<-EOR
      ec2-authorize -p 22 default
      ec2-authorize -p 80 default
    EOR
  end
end