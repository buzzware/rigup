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

		#argument :variant, :required => true, :type => :string, :desc => "whether live or stage or otherwise"

		attr_reader :context

		no_commands do

			def init(aPath=nil,aConfig={})
				return if @initialised
				@initialised = true
				aPath ||= aConfig[:site_dir] || Dir.pwd
				@site_dir = Buzztools::File.real_path(aPath) rescue File.expand_path(aPath)
				config = Rigup::Config.new(aConfig.merge(site_dir: @site_dir))
				@context = Rigup::Context.new(
					config: config,
					logger: ::Logger.new(STDOUT),
					pwd: Dir.pwd,
					stage: 'live'
				)
			end

			def site_dir
				@site_dir
			end

			def cache_dir
				File.join(@site_dir,'shared','cached-copy')
			end

			def config
				@context.config
			end

			# Prepares repo in cache dir for site
			# requires params: repo_url,site
			def prepare_cache # {:url=>'git://github.com/ddssda', :branch=>'master', :commit=>'ad452bcd'}
				url = config[:git_url]
				wd = cache_dir

				@repo = GitRepo.new
				suitable = if File.exists?(wd)
					@repo.open wd
					@repo.origin.url==url
				else
					false
				end

				if suitable
					@repo.fetch
				else
					if File.exists? wd
						#raise RuntimeError.new('almost did bad delete') if !@core.cache_dir || @core.cache_dir.length<3 || !wd.begins_with?(@core.cache_dir)
						FileUtils.rm_rf wd
					end
					@repo.clone(url, wd)
				end
			end

			# Switches @repo to given branch and/or commit
			# Should call prepare_cache first to create @repo
			# requires params: branch and/or commit
			def checkout_branch_commit
				#url = @params['repo_url']
				#site = @params['site']
				#wd = @core.working_dir_from_site(site)
				branch = config[:branch] || 'master'
				commit = config[:commit]
				@repo.checkout(commit,branch)
				#perhaps use reset --hard here
				if (commit)
					@repo.merge(commit,['--ff-only'])
				else
					@repo.merge('origin/'+branch,['--ff-only'])
				end
			end

			#desc "update_cache", "update the cache"
		  def update_cache(aPath=nil)
			  #init
				prepare_cache
			  checkout_branch_commit
		  end

			#desc "release", "create a new release from cache"
			def release
				init
				@release = Time.now.strftime('%Y%m%d%H%M%S')
				@release_path = File.expand_path(File.join(site_dir,'releases',@release))
				@repo.export(@release_path)
				return @release_path
			end

			#desc "link_live", "symlink the latest release as current"
			def link_live
				init
				ensure_link(@release_path,@current_path,nil,"#{@user}:#{@group}")
				after_link_live if respond_to? :after_link_live
			end

			#desc "migrate", "migrate the database"
			def	migrate
		    @rails_env ||= "production"
		    run "rake RAILS_ENV=#{@rails_env} db:migrate",@release_path
		  end

			#desc "cleanup", "keep @keep_releases, delete older ones"
			def cleanup
		    count = (@keep_releases || 3).to_i
		    if count >= releases.length
		      logger.important "no old releases to clean up"
		    else
		      logger.info "keeping #{count} of #{releases.length} deployed releases"

		      directories = (@releases - @releases.last(count)).map { |r|
		        File.join(@releases_path, r)
					}.join(" ")

		      run "rm -rf #{directories}"
		    end
			end

			#desc "restart", "restart the web server"
			def restart
				run "touch current/tmp/restart.txt && chown #{@user}:#{@group} current/tmp/restart.txt"
				run "/etc/init.d/apache2 restart --force-reload"
			end
		end

		public

		desc "new GIT_URL [PATH]", "setup new site"
		def new(aGitUrl,aPath=nil)
			aPath ||= File.basename(aGitUrl,'.git')
			init(
				aPath,
				git_url: aGitUrl
			)
			FileUtils.mkdir_p(site_dir)
			FileUtils.mkdir_p(File.join(site_dir,'releases'))
			FileUtils.mkdir_p(File.join(site_dir,'shared'))

			#+ create rigup.yml if doesn't exist, including option values
			context.config.to_hash.filter_exclude(:site_dir).to_yaml.to_file(File.join(site_dir,'rigup.yml'))
		end

		# desc "deploy", "deploy the given variant of this project"
		# def deploy
		# 	init
		# 	update_cache
		# 	release
		# 	install
		# 	#migrate
		# 	#link_live
		# 	#restart
		# 	#fixups_after_restart
		# end
	end
end
