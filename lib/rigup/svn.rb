module Rigup
	module Svn

		def svnInfo(aPath)
			cmdresult = run "svn info \"#{aPath}\""
			cmdresult = cmdresult.split("\n")
			result = {}
			cmdresult.each do |line|
				parts = line.split(': ')
				next if parts.length!=2 || !parts[0] || !parts[1]
				result[parts[0]] = parts[1]
			end

			if (url = result['URL']) && (root = result['Repository Root']) && url.start_with?(root)
				result['Short URL'] = url[root.length]
			end
			result
		end

		def svnCmd(aCommand,aSourceServer,aSourceUrl,aDestPath,aOptions = null)
			"svn #{aCommand} \"#{aSourceServer ? File.join(aSourceServer,aSourceUrl) : aSourceUrl}\" \"#{aDestPath}\" #{aOptions || ''}"
		end

		def svnCheckoutCmd(aConfig,aCommmand='checkout',aOptions=nil)
			options = []
			options << aOptions if aOptions
			options << '--username '+aConfig['vcs_username'] if aConfig['vcs_username']
			options << '--password '+aConfig['vcs_password'] if aConfig['vcs_password']
			options << '--revision '+aConfig['revision'] if aConfig['revision']
			options = options.join ' '

			rep = aConfig['repository'].to_s.chomp('/').to_nil
			if rep && (branch = aConfig['branch'])
				branch = '/'+branch unless branch.start_with? '/'
				url = File.join(branch,aConfig['source'].to_s) if aConfig['source']
			else
				url = aConfig['source']
			end
			url = url.chomp('/')

			svnCmd(aCommmand,rep,url,aConfig['destination'],options)
		end

		def createSvnConfig(aMergeOptions = nil)
			result = {
				'repository' => @repository,
				'source' => @vcs_app_path,
				'branch' => @branch,
				'destination' => release_path,
				'revision' => @revision
			}
			result.merge!(aMergeOptions) if aMergeOptions
			result
		end

		def folderIsSvn(aPath)
			return false unless File.exists?(aPath)
			info = svnInfo(aPath)
			return !!(info && info['URL'])
		end

		# ensure cache_path is an svn repo and is up to date. Checkout if not
		def ensureSvnCacheUpdate(cache_path,svnConfig)
			svnConfig = svnConfig.merge('destination' => cache_path)
			if File.exists?(cache_path)
				raise Error('Dir exists but not a svn folder') unless folderIsSvn(cache_path)
				run "svn revert --non-interactive --recursive \"#{cache_path}\""
				run svnCheckoutCmd(
					svnConfig,
					'switch',
					'--non-interactive'
				)
			else
				MiscUtils.mkdir?(MiscUtils.path_parent(cache_path))
				run svnCheckoutCmd(svnConfig,'checkout','--non-interactive')
			end
		end

	end
end