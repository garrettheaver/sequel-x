Gem::Specification.new do |s|
  s.name = 'sequelx'
  s.version = '0.0.1'
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary = 'library of custom sequel plugins'
  s.description = 'plugins which extend native sequel behaviour'
  s.authors = ['Garrett Heaver']
  s.email = 'garrett@iterationfour.com'
  s.homepage = 'https://github.com/garrettheaver/sequelx'
  s.license = 'IterationFour Proprietary'
  s.add_runtime_dependency 'sequel'
  s.files = Dir.glob('lib/**/*')
end
