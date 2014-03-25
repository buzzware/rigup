# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'rspec'
require 'rigup'

include Rigup

#RSpec.configure do |config|
#  def config.escaped_path(*parts)
#    Regexp.compile(parts.join('[\\\/]'))
#  end unless config.respond_to? :escaped_path
#end

# Include support files.
#Dir["#{File.expand_path('../', __FILE__)}/support/**/*.rb"].each { |f| require f }
