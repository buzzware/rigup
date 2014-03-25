#require_relative "../lib/rigup"
#
#begin
#  RCat::Application.new(ARGV).run
#rescue Errno::ENOENT => err
#  abort "rcat: #{err.message}"
#rescue OptionParser::InvalidOption => err
#  abort "rcat: #{err.message}\nusage: rcat [-bns] [file ...]"
#end
#
#
#

module Rigup
	class Cli < Thor
		desc "foo", "Prints foo"
		def foo
		  puts "foo"
		end
	end
end
