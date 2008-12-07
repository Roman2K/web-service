COVERAGE_OUT  = "doc/coverage"
COVERAGE_CODE = %w(lib)

task :default => :test

desc "Run the test suite"
task :test do
  all_test_files.each { |test| require test }
end

desc "Measure test coverage"
task :coverage do
  rm_rf COVERAGE_OUT; mkdir_p COVERAGE_OUT
  sh %(rcov -I.:lib:test -x '^(?!#{COVERAGE_CODE * '|'})/' --text-summary --sort coverage --no-validator-links -o #{COVERAGE_OUT} #{all_test_files * ' '})
  system %(open #{COVERAGE_OUT}/index.html)
end

def all_test_files
  Dir['test/**/*_test.rb'].sort
end
