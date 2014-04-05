module Rigup

	class Config < Buzztools::Config

		DEFAULTS = {
			site_dir: String,
			git_url: String
		}

		def initialize(aValues=nil)
			super(DEFAULTS,aValues)
		end

	end
end
