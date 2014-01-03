Gem::Specification.new do |s|
  s.name = 'sequel-x'
  s.version = '0.0.1'
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary = 'library of custom sequel plugins'
  s.description = 'plugins which extend native sequel behaviour'
  s.authors = ['Garrett Heaver']
  s.email = 'open.source@iterationfour.com'
  s.homepage = 'https://github.com/garrettheaver/sequel-x'
  s.license = 'MIT'
  s.add_runtime_dependency 'sequel'
  s.files = Dir.glob('lib/**/*')
end

