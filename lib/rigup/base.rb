module Rigup
	module Base

		def self.included(aClass)
	    aClass.class_eval do
		    no_commands do

			    def logger
				    @logger ||= ::Logger.new(STDOUT)
			    end

			    def config
				    unless @config
					    @config = {}
							if File.exists?(f=File.join(release_path,'rigup.yml'))
								file_config = YAML.load(String.from_file(f))
								@config.merge!(file_config)
								@config = Rigup::Config.new(@config)
							end
					  end
				    @config
			    end

			    def context
				    @context ||= Rigup::Context.new(
							:config => config,
							:logger => logger,
							:pwd => Dir.pwd,
						)
			    end

			    def release_path
				    @release_path ||= File.expand_path('.')
			    end

			    def site_dir
				    @site_dir ||= File.expand_path('../..',release_path)
			    end

			    def shared_path
			      @shared_path ||= File.expand_path('shared',site_dir)
			    end
			  end
	    end

		end
	end
end
