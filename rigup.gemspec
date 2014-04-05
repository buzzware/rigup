# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rigup/version"

Gem::Specification.new do |s|
  s.name        = "rigup"
  s.version     = Rigup::VERSION
  s.authors     = ["Gary McGhee"]
  s.email       = ["contact@buzzware.com.au"]
  s.homepage    = "http://github.com/buzzware/rigup"
  s.summary     = "Toolset for deployment"
  s.description = s.summary

  ignores = File.readlines(".gitignore").grep(/\S+/).map {|line| line.chomp }
 	dotfiles = [".gitignore"]
 	s.files = Dir["**/*"].reject {|f| File.directory?(f) || ignores.any? {|i| File.fnmatch(i, f) } } + dotfiles
	s.bindir = 'bin'
	s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	s.test_files    = s.files.grep(%r{^(test|spec|features)/})

  s.add_dependency 'bundler', '~>1.5.3'
  s.add_dependency 'thor', '~> 0.19.1'


  s.add_development_dependency 'rspec', '~>2.14.0'
  #s.add_development_dependency('rspec')

  s.add_development_dependency('rake')
  #s.add_development_dependency('rspec-core')
  #s.add_development_dependency('rdoc')
	#s.add_development_dependency('aruba')
	#s.add_development_dependency('debugger')
  #s.add_runtime_dependency('gli','2.5.0')
	#s.add_runtime_dependency('termios')
	#s.add_runtime_dependency('highline')
	#s.add_runtime_dependency('git')
	#s.add_runtime_dependency('middleman')
	#s.add_runtime_dependency('buzztools')
	s.add_runtime_dependency('POpen4')
	# https://github.com/geemus/formatador
	#s.add_runtime_dependency('bitbucket_rest_api')
	#s.add_runtime_dependency('osx_keychain')
	#s.add_runtime_dependency('json')
	#s.add_runtime_dependency('net_dav')
	#s.add_runtime_dependency('net-ssh')
	#s.add_runtime_dependency('system_timer')
end
