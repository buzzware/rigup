module Rigup

	class Config < Buzztools::Config

		DEFAULTS = {
			app_name: String,
			user: String,
			group: 'www',
			site_dir: String,
			git_url: String,
			branch: String,
			commit: String,
			stage: 'live',    # or 'staging' or 'development'
			block_command: nil,
			install_command: 'thor deploy:install',
			restart_command: 'thor deploy:restart',
			unblock_command: nil,
		}

		def initialize(aValues=nil)
			super(DEFAULTS,aValues)
		end

	end
end
