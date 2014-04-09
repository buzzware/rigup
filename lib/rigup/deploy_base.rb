module Rigup

	class DeployBase < Thor

		include Rigup::Runability
		include Rigup::InstallUtils

		no_commands do
			def initialize(*args)
				super
				@release_path = Dir.pwd
				@site_dir = File.expand_path('../..')
				@shared_path = File.expand_path('shared',@site_dir)
				config = {}
				if File.exists?(f=File.join(@release_path,'rigup.yml'))
					file_config = YAML.load(String.from_file(f))
					config.merge!(file_config)
				end
				@context = Rigup::Context.new(
					config: Rigup::Config.new(config),
					logger: ::Logger.new(STDOUT),
					pwd: Dir.pwd,
				)
			end

			def config
				@context.config
			end
		end

	end

end