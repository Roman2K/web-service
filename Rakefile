require "echoe"

Echoe.new('web-service', '0.1.1') do |p|
  p.description     = "REST client; an alternative to ActiveResource"
  p.url             = "https://github.com/Roman2K/web-service"
  p.author          = "Roman Le Négrate"
  p.email           = "roman.lenegrate@gmail.com"
  p.ignore_pattern  = "*.gemspec"
  p.dependencies    = ["activesupport >=2.2.2", "class-inheritable-attributes"]
  p.development_dependencies = ["mocha", "test-unit-ext"]
  p.rdoc_options    = %w(--main README.mdown --inline-source --line-numbers --charset UTF-8)
end

# Weirdly enough, Echoe's default `test' task doesn't get overridden by the one
# defined below. Even weirder, `rake test' runs both tasks! The same applies to
# `coverage'. Dirty workaround:
%w(test coverage).each do |name|
  Rake.application.instance_eval("@tasks").delete(name)
end

task :default => :test

desc "Run the test suite"
task :test do
  all_test_files.each { |test| require test }
end

desc "Measure test coverage"
COVERAGE_OUT  = "doc/coverage"
COVERAGE_CODE = %w(lib)
task :coverage do
  rm_rf COVERAGE_OUT; mkdir_p COVERAGE_OUT
  sh %(rcov -I.:lib:test -x '^(?!#{COVERAGE_CODE * '|'})/' --text-summary --sort coverage --no-validator-links -o #{COVERAGE_OUT} #{all_test_files * ' '})
  system %(open #{COVERAGE_OUT}/index.html)
end

def all_test_files
  Dir['test/**/*_test.rb'].sort
end
