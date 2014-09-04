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

  s.add_dependency 'bundler'#, '~>1.5.3'
  s.add_dependency 'thor'#, '~> 0.19.1'
	s.add_runtime_dependency('git')
	s.add_runtime_dependency('session')
	# https://github.com/geemus/formatador

  s.add_development_dependency 'rspec', '~>2.14.0'
  s.add_development_dependency('rake')
end
