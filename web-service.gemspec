# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{web-service}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Roman Le N\303\251grate"]
  s.date = %q{2009-03-17}
  s.description = %q{REST client; an alternative to ActiveResource}
  s.email = %q{roman.lenegrate@gmail.com}
  s.extra_rdoc_files = ["lib/web_service/attribute_accessors.rb", "lib/web_service/core_ext.rb", "lib/web_service/crud_operations.rb", "lib/web_service/named_request_methods.rb", "lib/web_service/remote_collection.rb", "lib/web_service/resource.rb", "lib/web_service/response_handling.rb", "lib/web_service/site.rb", "lib/web_service.rb", "LICENSE", "README.mdown"]
  s.files = ["lib/web_service/attribute_accessors.rb", "lib/web_service/core_ext.rb", "lib/web_service/crud_operations.rb", "lib/web_service/named_request_methods.rb", "lib/web_service/remote_collection.rb", "lib/web_service/resource.rb", "lib/web_service/response_handling.rb", "lib/web_service/site.rb", "lib/web_service.rb", "LICENSE", "Manifest", "Rakefile", "README.mdown", "test/test_helper.rb", "test/web_service/attribute_accessors_test.rb", "test/web_service/core_ext_test.rb", "test/web_service/crud_operations_test.rb", "test/web_service/named_request_methods_test.rb", "test/web_service/remote_collection_test.rb", "test/web_service/resource_test.rb", "test/web_service/response_handling_test.rb", "test/web_service/site_test.rb", "web-service.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{https://github.com/Roman2K/web-service}
  s.rdoc_options = ["--main", "README.mdown", "--inline-source", "--line-numbers", "--charset", "UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{web-service}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{REST client; an alternative to ActiveResource}
  s.test_files = ["test/test_helper.rb", "test/web_service/attribute_accessors_test.rb", "test/web_service/core_ext_test.rb", "test/web_service/crud_operations_test.rb", "test/web_service/named_request_methods_test.rb", "test/web_service/remote_collection_test.rb", "test/web_service/resource_test.rb", "test/web_service/response_handling_test.rb", "test/web_service/site_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.2.2"])
      s.add_runtime_dependency(%q<class-inheritable-attributes>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<test-unit-ext>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.2.2"])
      s.add_dependency(%q<class-inheritable-attributes>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<test-unit-ext>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.2.2"])
    s.add_dependency(%q<class-inheritable-attributes>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<test-unit-ext>, [">= 0"])
  end
end
