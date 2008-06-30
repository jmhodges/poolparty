Gem::Specification.new do |s|
  s.name = %q{poolparty}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new("= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ari Lerner"]
  s.cert_chain = nil
  s.date = %q{2008-06-30}
  s.description = %q{Run your entire application off EC2, managed and auto-scaling}
  s.email = %q{ari.lerner@citrusbyte.com}
  s.executables = ["instance", "pool", "poolnotify"]
  s.extra_rdoc_files = ["CHANGELOG", "README.txt", "bin", "bin/instance", "bin/pool", "bin/poolnotify", "lib", "lib/core", "lib/core/array.rb", "lib/core/exception.rb", "lib/core/float.rb", "lib/core/hash.rb", "lib/core/kernel.rb", "lib/core/module.rb", "lib/core/object.rb", "lib/core/proc.rb", "lib/core/string.rb", "lib/core/time.rb", "lib/helpers", "lib/helpers/plugin_spec_helper.rb", "lib/modules", "lib/modules/callback.rb", "lib/modules/ec2_wrapper.rb", "lib/modules/file_writer.rb", "lib/modules/safe_instance.rb", "lib/modules/sprinkle_overrides.rb", "lib/modules/vlad_override.rb", "lib/poolparty", "lib/poolparty.rb", "lib/poolparty/application.rb", "lib/poolparty/init.rb", "lib/poolparty/master.rb", "lib/poolparty/monitors", "lib/poolparty/monitors.rb", "lib/poolparty/monitors/cpu.rb", "lib/poolparty/monitors/memory.rb", "lib/poolparty/monitors/web.rb", "lib/poolparty/optioner.rb", "lib/poolparty/plugin.rb", "lib/poolparty/plugin_manager.rb", "lib/poolparty/provider", "lib/poolparty/provider.rb", "lib/poolparty/provider/packages", "lib/poolparty/provider/packages/essential.rb", "lib/poolparty/provider/packages/git.rb", "lib/poolparty/provider/packages/haproxy.rb", "lib/poolparty/provider/packages/heartbeat.rb", "lib/poolparty/provider/packages/monit.rb", "lib/poolparty/provider/packages/rsync.rb", "lib/poolparty/provider/packages/ruby.rb", "lib/poolparty/provider/packages/s3fuse.rb", "lib/poolparty/provider/provider.rb", "lib/poolparty/remote_instance.rb", "lib/poolparty/remoter.rb", "lib/poolparty/remoting.rb", "lib/poolparty/scheduler.rb", "lib/poolparty/tasks", "lib/poolparty/tasks.rb", "lib/poolparty/tasks/cloud.rake", "lib/poolparty/tasks/development.rake", "lib/poolparty/tasks/ec2.rake", "lib/poolparty/tasks/instance.rake", "lib/poolparty/tasks/package.rake", "lib/poolparty/tasks/plugins.rake", "lib/poolparty/tasks/server.rake", "lib/s3", "lib/s3/s3_object_store_folders.rb"]
  s.files = ["CHANGELOG", "README.txt", "Rakefile", "assets", "assets/clouds.png", "bin", "bin/instance", "bin/pool", "bin/poolnotify", "config", "config/cloud_master_takeover", "config/create_proxy_ami.sh", "config/haproxy.conf", "config/heartbeat.conf", "config/heartbeat_authkeys.conf", "config/installers", "config/installers/ubuntu_install.sh", "config/monit", "config/monit.conf", "config/monit/haproxy.monit.conf", "config/monit/nginx.monit.conf", "config/nginx.conf", "config/reconfigure_instances_script.sh", "config/sample-config.yml", "config/scp_instances_script.sh", "lib", "lib/core", "lib/core/array.rb", "lib/core/exception.rb", "lib/core/float.rb", "lib/core/hash.rb", "lib/core/kernel.rb", "lib/core/module.rb", "lib/core/object.rb", "lib/core/proc.rb", "lib/core/string.rb", "lib/core/time.rb", "lib/helpers", "lib/helpers/plugin_spec_helper.rb", "lib/modules", "lib/modules/callback.rb", "lib/modules/ec2_wrapper.rb", "lib/modules/file_writer.rb", "lib/modules/safe_instance.rb", "lib/modules/sprinkle_overrides.rb", "lib/modules/vlad_override.rb", "lib/poolparty", "lib/poolparty.rb", "lib/poolparty/application.rb", "lib/poolparty/init.rb", "lib/poolparty/master.rb", "lib/poolparty/monitors", "lib/poolparty/monitors.rb", "lib/poolparty/monitors/cpu.rb", "lib/poolparty/monitors/memory.rb", "lib/poolparty/monitors/web.rb", "lib/poolparty/optioner.rb", "lib/poolparty/plugin.rb", "lib/poolparty/plugin_manager.rb", "lib/poolparty/provider", "lib/poolparty/provider.rb", "lib/poolparty/provider/packages", "lib/poolparty/provider/packages/essential.rb", "lib/poolparty/provider/packages/git.rb", "lib/poolparty/provider/packages/haproxy.rb", "lib/poolparty/provider/packages/heartbeat.rb", "lib/poolparty/provider/packages/monit.rb", "lib/poolparty/provider/packages/rsync.rb", "lib/poolparty/provider/packages/ruby.rb", "lib/poolparty/provider/packages/s3fuse.rb", "lib/poolparty/provider/provider.rb", "lib/poolparty/remote_instance.rb", "lib/poolparty/remoter.rb", "lib/poolparty/remoting.rb", "lib/poolparty/scheduler.rb", "lib/poolparty/tasks", "lib/poolparty/tasks.rb", "lib/poolparty/tasks/cloud.rake", "lib/poolparty/tasks/development.rake", "lib/poolparty/tasks/ec2.rake", "lib/poolparty/tasks/instance.rake", "lib/poolparty/tasks/package.rake", "lib/poolparty/tasks/plugins.rake", "lib/poolparty/tasks/server.rake", "lib/s3", "lib/s3/s3_object_store_folders.rb", "spec", "spec/application_spec.rb", "spec/callback_spec.rb", "spec/core_spec.rb", "spec/ec2_wrapper_spec.rb", "spec/file_writer_spec.rb", "spec/files", "spec/files/describe_response", "spec/files/multi_describe_response", "spec/files/remote_desc_response", "spec/helpers", "spec/helpers/ec2_mock.rb", "spec/kernel_spec.rb", "spec/master_spec.rb", "spec/monitors", "spec/monitors/cpu_monitor_spec.rb", "spec/monitors/memory_spec.rb", "spec/monitors/misc_monitor_spec.rb", "spec/monitors/web_spec.rb", "spec/optioner_spec.rb", "spec/plugin_manager_spec.rb", "spec/plugin_spec.rb", "spec/pool_binary_spec.rb", "spec/poolparty_spec.rb", "spec/provider_spec.rb", "spec/remote_instance_spec.rb", "spec/remoter_spec.rb", "spec/remoting_spec.rb", "spec/scheduler_spec.rb", "spec/spec_helper.rb", "spec/string_spec.rb", "poolparty.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://blog.citrusbyte.com}
  s.post_install_message = %q{
      
      Get ready to jump in the pool, you just installed PoolParty! (Updated at 02:33PM, 06/30/08)

      Please check out the documentation for any questions or check out the google groups at
        http://groups.google.com/group/poolpartyrb

      Don't forget to check out the plugin tutorial @ http://poolpartyrb.com for extending PoolParty!      

      For more information, check http://poolpartyrb.com
      On IRC: 
        irc.freenode.net
        #poolpartyrb
      *** Ari Lerner @ <ari.lerner@citrusbyte.com> ***
    }
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Poolparty", "--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{poolparty}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Run your entire application off EC2, managed and auto-scaling}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<aws-s3>, [">= 0"])
      s.add_runtime_dependency(%q<amazon-ec2>, [">= 0"])
      s.add_runtime_dependency(%q<auser-aska>, [">= 0"])
      s.add_runtime_dependency(%q<git>, [">= 0"])
      s.add_runtime_dependency(%q<crafterm-sprinkle>, [">= 0"])
      s.add_runtime_dependency(%q<SystemTimer>, [">= 0"])
    else
      s.add_dependency(%q<aws-s3>, [">= 0"])
      s.add_dependency(%q<amazon-ec2>, [">= 0"])
      s.add_dependency(%q<auser-aska>, [">= 0"])
      s.add_dependency(%q<git>, [">= 0"])
      s.add_dependency(%q<crafterm-sprinkle>, [">= 0"])
      s.add_dependency(%q<SystemTimer>, [">= 0"])
    end
  else
    s.add_dependency(%q<aws-s3>, [">= 0"])
    s.add_dependency(%q<amazon-ec2>, [">= 0"])
    s.add_dependency(%q<auser-aska>, [">= 0"])
    s.add_dependency(%q<git>, [">= 0"])
    s.add_dependency(%q<crafterm-sprinkle>, [">= 0"])
    s.add_dependency(%q<SystemTimer>, [">= 0"])
  end
end
