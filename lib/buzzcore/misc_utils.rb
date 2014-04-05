require 'tmpdir'
require 'logger'
require 'pathname'

require 'buzzcore/logging'

module MiscUtils

	module_function

	public

	def file_extension(aFile,aExtended=true)
		f = File.basename(aFile)
		dot = aExtended ? f.index('.') : f.rindex('.')
		return dot ? f[dot+1..-1] : f
	end

	def file_no_extension(aFile,aExtended=true)
		ext = file_extension(aFile,aExtended)
		return aFile.chomp('.'+ext)
	end

end