require 'sequel'

lib = File.expand_path('../../lib', __FILE__)
$:.unshift(lib) unless $:.include?(lib)

RSpec::configure do |c|
  c.expect_with :stdlib, :rspec
end

