require "echoe"

Echoe.new('web-service', '0.1.0') do |p|
  p.description     = "REST client; an alternative to ActiveResource"
  p.url             = "https://github.com/Roman2K/web-service"
  p.author          = "Roman Le Négrate"
  p.email           = "roman.lenegrate@gmail.com"
  p.ignore_pattern  = "*.gemspec"
  p.dependencies    = ["active_support", "Roman2K-class-inheritable-attributes"]
  p.development_dependencies = []
  p.rdoc_options    = %w(--main README.mdown --inline-source --line-numbers --charset UTF-8)
end

# Weirdly enough, Echoe's default `test' task doesn't get overridden by the one defined
# below. Even weirder, `rake test' runs both tasks! Dirty workaround:
Rake.application.instance_eval("@tasks").delete("test")

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
