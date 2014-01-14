Gem::Specification.new do |s|
  s.name        = 'sitemapper'
  s.version     = '0.0.1'
  s.date        = '2014-01-11'
  s.summary     = "Hola!"
  s.description = "It's a sitemapper gem"
  s.authors     = ["Patrick McGuire"]
  s.email       = 'pjm1988@gmail.com'
  s.files       = ["lib/sitemapper.rb"]
  s.license       = 'MIT'
  s.add_development_dependency 'rspec'
  s.add_runtime_dependency 'public_suffix'
  s.add_runtime_dependency 'capybara-webkit'
  s.add_runtime_dependency 'sinatra'
end
