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

		attr_reader :context, :release_path

		no_commands do

			def init(aPath=nil,aConfig={})
				return if @initialised
				@initialised = true
				aPath ||= aConfig[:site_dir] || Dir.pwd
				@site_dir = Buzztools::File.real_path(aPath) rescue File.expand_path(aPath)
				@releases_path = File.join(@site_dir,'releases')
				if File.exists?(f=File.join(@site_dir,'rigup.yml'))
					file_config = YAML.load(String.from_file(f))
					aConfig.merge!(file_config)
				end
				config = Rigup::Config.new(aConfig.merge(site_dir: @site_dir))
				@context = Rigup::Context.new(
					config: config,
					logger: ::Logger.new(STDOUT),
					pwd: Dir.pwd,
					stage: 'live'
				)
				@install_utils = Rigup::InstallUtils.new(@context)
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
			
			def repo
				@repo ||= GitRepo.new(@context)
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
				#url = @params['repo_url']
				#site = @params['site']
				#wd = @core.working_dir_from_site(site)
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

			#desc "update_cache", "update the cache"
		  def update_cache(aPath=nil)
			  #init
				prepare_cache
			  checkout_branch_commit
		  end

			#desc "release", "create a new release from cache"
			def release
				#init
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

			def install
				@install_utils.run config[:install_command],@release_path
			end

			#desc "link_live", "symlink the latest release as current"
			def link_live
				#init
				@install_utils.ensure_link(@release_path,File.expand_path(File.join(site_dir,'current')))
				#after_link_live if respond_to? :after_link_live
			end

			#desc "migrate", "migrate the database"
			def	migrate
		    @rails_env ||= "production"
		    @install_utils.run "rake RAILS_ENV=#{@rails_env} db:migrate",@release_path
		  end

			#desc "cleanup", "keep @keep_releases, delete older ones"
			def cleanup
				@releases = @install_utils.run("ls -x #{@releases_path}").split.sort
		    count = (@keep_releases || 3).to_i
		    if count >= @releases.length
		      @context.logger.info "no old releases to clean up"
		    else
			    @context.logger.info "keeping #{count} of #{@releases.length} deployed releases"

		      directories = (@releases - @releases.last(count)).map { |r|
		        File.join(@releases_path, r)
					}.join(" ")

		      @install_utils.run "rm -rf #{directories}"
		    end
			end

			# #desc "restart", "restart the web server"
			# def restart
			# 	run "touch current/tmp/restart.txt && chown #{@user}:#{@group} current/tmp/restart.txt"
			# 	run "/etc/init.d/apache2 restart --force-reload"
			# end

			def is_rails?
				File.exists?(File.expand_path('Rakefile',release_path))
			end

DEPLOY_THOR_CONTENT = <<-EOS
# This file will be called deploy.thor and lives in the root of the project repositiory, so it is version controlled
# and can be freely modified to suit the project requirements
class Deploy < RigupBaseDeploy  # from gem, sets context and loads rigup.yml into config from site_dir

	# You are free to modify these two tasks to suit your requirements

	desc 'install','install the freshly delivered files'
	def install
		@release_path = File.basedir(__FILE__)
		@shared_path = File.expand_path('../../shared',@release_path)
		case config.stage
			when 'live'
				@user = 'apache'
				@group = 'apache'
			when 'staging'
				@user = 'apache'
				@group = 'apache'
			else
				raise 'invalid stage'
		end

		select_variant_file("#{@release_path}/config/database.yml")
		select_variant_file("#{@release_path}/yore.config.xml")
		select_variant_file("#{@release_path}/config/app_config.xml")
		select_variant_file("#{@release_path}/system/apache.site")
		#make_public_cache_dir("#{@release_path}/public/cache")

		ensure_link("#{@shared_path}/log","#{@release_path}/log")
		ensure_link("#{@shared_path}/pids","#{@release_path}/tmp/pids")
		ensure_link("#{@shared_path}/uploads","#{@release_path}/tmp/uploads")
		ensure_link("#{@shared_path}/system","#{@release_path}/public/system")

		#run "touch #{@shared_path}/log/production.log && chown #{@user}:#{@group} #{@shared_path}/log/production.log && chmod 666 #{@shared_path}/log/production.log"
	end

	desc 'restart','restart the web server'
	def restart
		run "touch current/tmp/restart.txt" # && chown user:group current/tmp/restart.txt"
		run "/etc/init.d/apache2 restart --force-reload"
	end

end
EOS

			def write_deploy_thor
				DEPLOY_THOR_CONTENT.to_file File.expand_path('deploy.thor',site_dir)
			end

			def call_release_command(aCommand)
				return unless cmdline = config["#{aCommand}_command".to_sym].to_s.strip.to_nil
				@install_utils.run cmdline, @release_path
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
			write_deploy_thor
		end

		desc "deploy", "deploy the given variant of this project"
		def deploy(aPath)
			init(aPath)
			update_cache
			release
			call_release_command(:install)     # call install_command if defined eg. defaults to "thor deploy:install" eg. make changes to files
			link_live
			call_release_command(:restart)     # call restart_command, defaults to "thor deploy:restart" eg. restart passenger
			cleanup
		end
	end
end
