require 'sequel'

lib = File.expand_path('../../lib', __FILE__)
$:.unshift(lib) unless $:.include?(lib)

RSpec::configure do |c|
  c.expect_with :minitest, :rspec
  c.run_all_when_everything_filtered = true
  c.filter_run :only => true
end

