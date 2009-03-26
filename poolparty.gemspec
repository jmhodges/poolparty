# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{poolparty}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ari Lerner"]
  s.date = %q{2009-03-26}
  s.description = %q{Self-healing, auto-scaling system administration, provisioning and maintaining tool that makes cloud computing fun and easy}
  s.email = %q{ari.lerner@citrusbyte.com}
  s.extra_rdoc_files = ["README.txt", "License.txt", "History.txt"]
  s.files = ["test/test_generator_helper.rb", "test/test_helper.rb", "test/test_pool_spec_generator.rb", "test/test_poolparty.rb", "README.txt", "License.txt", "History.txt"]
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
      s.add_runtime_dependency(%q<grempe-amazon-ec2>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<logging>, [">= 0"])
      s.add_dependency(%q<ruby2ruby>, [">= 0"])
      s.add_dependency(%q<grempe-amazon-ec2>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<logging>, [">= 0"])
    s.add_dependency(%q<ruby2ruby>, [">= 0"])
    s.add_dependency(%q<grempe-amazon-ec2>, [">= 0"])
  end
end
