module Rigup
	class Cli < Thor

		include Rigup::Utils::Run
		include Rigup::Utils::Install

		no_commands do

			def logger
		    @logger ||= ::Logger.new(STDOUT)
      end

			def config
				@context.config
			end

			def init(aPath=nil,aConfig={})
				return if @initialised
				@initialised = true
				aPath ||= aConfig[:site_dir] || Dir.pwd
				@site_dir = Rigup::Utils::File.real_path(aPath) rescue File.expand_path(aPath)
				@releases_path = File.join(@site_dir,'releases')
				if File.exists?(f=File.join(@site_dir,'rigup.yml'))
					file_config = YAML.load(String.from_file(f))
					aConfig.merge!(file_config)
				end
				aConfig = aConfig.merge(site_dir: @site_dir)
				aConfig[:user] ||= ENV['USER']
				config = Rigup::Config.new(aConfig)
				@context = Rigup::Context.new(
					config: config,
					logger: ::Logger.new(STDOUT),
					pwd: Dir.pwd
				)
			end

			attr_reader :context, :release_path, :site_dir

			def shared_path
        @shared_path ||= File.expand_path('shared',site_dir)
      end

			def cache_dir
				File.join(site_dir,'shared','cached-copy')
			end

			def repo
				@repo ||= GitRepo.new(context)
			end

			# Prepares repo in cache dir for site
			# requires params: repo_url,site
			def prepare_cache # {:url=>'git://github.com/ddssda', :branch=>'master', :commit=>'ad452bcd'}
				url = config[:git_url]
				wd = cache_dir

				suitable = if File.exists?(wd)
					repo.open wd
					repo.origin.url==url
				else
					false
				end

				if suitable
					repo.fetch
				else
					if File.exists? wd
						#raise RuntimeError.new('almost did bad delete') if !@core.cache_dir || @core.cache_dir.length<3 || !wd.begins_with?(@core.cache_dir)
						FileUtils.rm_rf wd
					end
					repo.clone(url, wd)
				end
			end

			# Switches @repo to given branch and/or commit
			# Should call prepare_cache first to create @repo
			# requires params: branch and/or commit
			def checkout_branch_commit
				branch = config[:branch] || 'master'
				commit = config[:commit]
				repo.open(cache_dir)
				repo.checkout(commit,branch)
				#perhaps use reset --hard here
				if (commit)
					repo.merge(commit,['--ff-only'])
				else
					repo.merge('origin/'+branch,['--ff-only'])
				end
			end

		  def update_cache(aPath=nil)
				prepare_cache
			  checkout_branch_commit
		  end

			def release
				release = Time.now.strftime('%Y%m%d%H%M%S')
				@release_path = File.expand_path(release,@releases_path)
				repo.open(cache_dir)
				repo.export(@release_path)
				release_config = context.config.to_hash
				release_config[:commit] = repo.head.sha
				release_config[:branch] = repo.branch
				release_config.to_yaml.to_file(File.join(@release_path,'rigup.yml'))
				return @release_path
			end

			def link_live
				ensure_link(release_path,File.expand_path(File.join(site_dir,'current')),"#{config[:user]}:#{config[:group]}")
			end

			def cleanup
				@releases = run("ls -x #{@releases_path}").split.sort
		    count = (@keep_releases || 3).to_i
		    if count >= @releases.length
		      logger.info "no old releases to clean up"
		    else
			    logger.info "keeping #{count} of #{@releases.length} deployed releases"

		      directories = (@releases - @releases.last(count)).map { |r|
		        File.join(@releases_path, r)
					}.join(" ")

		      run "rm -rf #{directories}"
		    end
			end

			def call_release_command(aCommand)
				return unless cmdline = config["#{aCommand}_command".to_sym].to_s.strip.to_nil
				cd release_path do
					run cmdline
				end
			end
		end

		public

		desc "new GIT_URL [PATH]", "setup new site"
		def new(aGitUrl,aPath=nil)
			app_name = File.basename(aGitUrl,'.git')
			aPath ||= app_name
			init(
				aPath,
				git_url: aGitUrl,
				app_name: app_name,
				user: ENV['USER']
			)
			FileUtils.mkdir_p(site_dir)
			FileUtils.mkdir_p(File.join(site_dir,'releases'))
			FileUtils.mkdir_p(File.join(site_dir,'shared'))

			#+ create rigup.yml if doesn't exist, including option values
			h = context.config.to_hash
			h.delete :site_dir
			h.to_yaml.to_file(File.join(site_dir,'rigup.yml'))
		end

		desc "deploy [PATH]", "deploy the given site"
		def deploy(aPath=nil)
			init(aPath)
			update_cache
			release
			call_release_command(:install)     # call install_command if defined eg. defaults to "thor deploy:install" eg. make changes to files
			call_release_command(:block)
			link_live
			call_release_command(:restart)     # call restart_command, defaults to "thor deploy:restart" eg. restart passenger
			call_release_command(:unblock)
			cleanup
		end

		desc "restart [PATH]", "restart the given site"
		def restart(aPath=nil)
			init(aPath)
			return unless cmdline = config["restart_command".to_sym].to_s.strip.to_nil
			cd File.join(site_dir,'current') do
				run cmdline
			end
		end

	end
end
