# -*- mode: ruby -*-

Gem::Specification.new do |s|
  s.name = "mongoid_attachment"
  s.version = "0.0.1"
  s.author = "Eric Kidd"
  s.email = "git@randomhacks.net"
  s.homepage = "http://github.com/emk/mongoid_attachment"
  s.platform = Gem::Platform::RUBY
  s.summary = "Lightweight file attachments for Mongoid"
  s.require_path = "lib"

  s.add_dependency('mongoid', '~> 1.2.14')
  s.add_dependency('mongo', '>= 1.0.1')
  s.add_dependency('bson_ext', '>= 1.0.1')

  s.add_development_dependency('rake', '>= 0.8.3')
  s.add_development_dependency('rspec', '>= 1.3.0')
end                    
