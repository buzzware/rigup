module Rigup

	class Config < Buzztools::Config

		DEFAULTS = {
			site_dir: String,
			git_url: String,
			branch: String,
			commit: String,
			stage: 'live',    # or 'staging' or 'development'
			install_command: 'thor deploy:install',
			restart_command: 'thor deploy:restart'
		}

		def initialize(aValues=nil)
			super(DEFAULTS,aValues)
		end

	end
end
