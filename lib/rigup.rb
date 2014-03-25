#begin
#  require "bundler/setup"
#rescue LoadError
#  require "rubygems"
#  require "bundler/setup"
#end
#
require "thor"
#Dir.chdir(File.dirname(__FILE__)) { Dir['rigup/*.rb'] }.each {|f| require f }
require_relative "rigup/version"
require_relative "rigup/cli"
