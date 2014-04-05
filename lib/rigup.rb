#begin
#  require "bundler/setup"
#rescue LoadError
#  require "rubygems"
#  require "bundler/setup"
#end
#
require "thor"
require "buzztools"
require "logger"

#Dir.chdir(File.dirname(__FILE__)) { Dir['rigup/*.rb'] }.each {|f| require f }
require_relative "rigup/version"
require_relative "rigup/config"
require_relative "rigup/context"
require_relative "rigup/contextable"
require_relative "rigup/git_repo"
require_relative "rigup/install_utils"
require_relative "rigup/utils"
require_relative "rigup/cli"
