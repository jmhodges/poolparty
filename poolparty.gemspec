# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{poolparty}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ari Lerner"]
  s.date = %q{2009-03-26}
  s.description = %q{Self-healing, auto-scaling system administration, provisioning and maintaining tool that makes cloud computing fun and easy}
  s.email = %q{ari.lerner@citrusbyte.com}
  s.executables = ["cloud", "cloud-add-access", "cloud-add-keypair", "cloud-configure", "cloud-contract", "cloud-expand", "cloud-handle-load", "cloud-list", "cloud-maintain", "cloud-osxcopy", "cloud-provision", "cloud-refresh", "cloud-rsync", "cloud-run", "cloud-setup-dev", "cloud-spec", "cloud-ssh", "cloud-start", "cloud-stats", "cloud-terminate", "messenger-get-current-nodes", "pool", "pool-console", "pool-describe", "pool-generate", "pool-init", "pool-list", "pool-start", "server-become-master", "server-build-messenger", "server-clean-cert-for", "server-ensure-provisioning", "server-fire-cmd", "server-get-load", "server-list-active", "server-list-responding", "server-provision", "server-query-agent", "server-rerun", "server-send-command", "server-show-stats", "server-start-agent", "server-start-client", "server-start-master", "server-start-node", "server-stop-client", "server-stop-master", "server-stop-node", "server-update-hosts", "server-write-new-nodes"]
  s.extra_rdoc_files = ["README.txt", "License.txt", "History.txt"]
  s.files = ["test/test_generator_helper.rb", "test/test_helper.rb", "test/test_pool_spec_generator.rb", "test/test_poolparty.rb", "bin/cloud", "bin/cloud-add-access", "bin/cloud-add-keypair", "bin/cloud-configure", "bin/cloud-contract", "bin/cloud-expand", "bin/cloud-handle-load", "bin/cloud-list", "bin/cloud-maintain", "bin/cloud-osxcopy", "bin/cloud-provision", "bin/cloud-refresh", "bin/cloud-rsync", "bin/cloud-run", "bin/cloud-setup-dev", "bin/cloud-spec", "bin/cloud-ssh", "bin/cloud-start", "bin/cloud-stats", "bin/cloud-terminate", "bin/messenger-get-current-nodes", "bin/pool", "bin/pool-console", "bin/pool-describe", "bin/pool-generate", "bin/pool-init", "bin/pool-list", "bin/pool-start", "bin/server-become-master", "bin/server-build-messenger", "bin/server-clean-cert-for", "bin/server-ensure-provisioning", "bin/server-fire-cmd", "bin/server-get-load", "bin/server-list-active", "bin/server-list-responding", "bin/server-provision", "bin/server-query-agent", "bin/server-rerun", "bin/server-send-command", "bin/server-show-stats", "bin/server-start-agent", "bin/server-start-client", "bin/server-start-master", "bin/server-start-node", "bin/server-stop-client", "bin/server-stop-master", "bin/server-stop-node", "bin/server-update-hosts", "bin/server-write-new-nodes", "README.txt", "License.txt", "History.txt"]
  s.has_rdoc = true
  s.homepage = %q{http://poolpartyrb.com}
  s.rdoc_options = ["--quiet", "--title", "PoolParty documentation", "--opname", "index.html", "--line-numbers", "--main", "README", "--inline-source", "--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Self-healing, auto-scaling system administration, provisioning and maintaining tool that makes cloud computing fun and easy}
  s.test_files = ["test/test_generator_helper.rb", "test/test_helper.rb", "test/test_pool_spec_generator.rb", "test/test_poolparty.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<logging>, [">= 0"])
      s.add_runtime_dependency(%q<ruby2ruby>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<logging>, [">= 0"])
      s.add_dependency(%q<ruby2ruby>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<logging>, [">= 0"])
    s.add_dependency(%q<ruby2ruby>, [">= 0"])
  end
end
