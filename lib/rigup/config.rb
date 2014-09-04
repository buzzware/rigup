module Rigup

	class Config < Rigup::Utils::Config

		DEFAULTS = {
			:app_name => String,
			:user => String,
			:group => 'www',
			:site_dir => String,
			:git_url => String,
			:branch => String,
			:commit => String,
			:stage => 'live',    # or 'staging' or 'development'
			:sudo => 'sudo',
			:block_command => nil,
			:install_command => 'bundle exec thor deploy:install',
			:restart_command => 'bundle exec thor deploy:restart',
			:unblock_command => nil
		}

		def initialize(aValues=nil)
			super(DEFAULTS,aValues)
		end

	end
end
