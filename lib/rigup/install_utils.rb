module Rigup
	module InstallUtils

		def select_suffixed_file(aFile,aExtendedExtension=false)
			ext = Buzztools::File.extension(aFile,aExtendedExtension)
			no_ext = Buzztools::File.no_extension(aFile,aExtendedExtension)
			dir = File.dirname(aFile)
			run "#{@context.sudo} mv -f #{no_ext}.#{@context.config[:stage]}.#{ext} #{aFile}"
			run "#{@context.sudo} rm -f #{no_ext}.*.#{ext}"
		end

		# Especially for modifiying behaviour eg. of FCKEditor without upsetting the standard files
		# eg. create a public_override folder that duplicates the same structure as public,
		# and contains the modified files. On deployment call
		#		override_folder("#{@release_path}/public")		# equiv to override_folder("#{@release_path}/public", "#{@release_path}/public_override")
		# and the files in public_override will be copied over public, then public_override removed
		def override_folder(aFolder,aOverrideFolder=nil,aRemove=true)
			aFolder = aFolder.desuffix('/')
			aOverrideFolder ||= (aFolder+'_override')
			run "#{@context.sudo} cp -vrf #{aOverrideFolder}/* #{aFolder}/"
			run "#{@context.sudo} rm -rf #{aOverrideFolder}" if aRemove
		end


		# set standard permissions for web sites - readonly for apache user
		def permissions_for_web(aPath,aUser=nil,aGroup=nil,aHideScm=nil)
			aUser ||= @user
			aGroup ||= @group

			run "#{@context.sudo} chown -R #{aUser}:#{aGroup} #{aPath.ensure_suffix('/')}"
			run_for_all("chmod 755",aPath,:dirs)									# !!! perhaps reduce other permissions
			run_for_all("chmod 644",aPath,:files)
			run_for_all("chmod g+s",aPath,:dirs)
			case aHideScm
				when :svn then run_for_all("chmod -R 700",aPath,:dirs,"*/.svn")
			end
		end

		# run this after permissions_for_web() on dirs that need to be writable by group (apache)
		def permissions_for_web_writable(aPath)
			run "chmod -R g+w #{aPath.ensure_suffix('/')}"
			run_for_all("chmod -R 700",aPath,:dirs,"*/.svn")
		end

		def internal_permissions(aPath,aKind)
			case aKind
				when 'rails' then
					permissions_for_web(aPath,@user,@group,true)

					run_for_all("chmod +x",File.join(aPath,'script'),:files)


					uploads = @shared_path+'/uploads'
					make_public_cache_dir(uploads)
					#if File.exists?(uploads)
					#	permissions_for_web(uploads,@user,@group,true)
					#	permissions_for_web_writable(uploads)
					#end
					#permissions_for_web_writable("#{aPath}/tmp")
					make_public_cache_dir("#{aPath}/tmp")

					run "#{@context.sudo} chown #{@apache_user} #{aPath}/config/environment.rb" unless DEV_MODE	# very important for passenger, which uses the owner of this file to run as

				when 'spree' then
					internal_permissions(aPath,'rails')
				when 'browsercms' then
					internal_permissions(aPath,'rails')
			end
		end

		def apply_permissions(aPath=nil,aKind=nil)
			aPath ||= @release_path
			aKind ||= @kind || 'rails'
			internal_permissions(aPath, aKind)
		end

		def ensure_link(aTo,aFrom,aUserGroup=nil,aSudo='')
			raise "Must supply from" if !aFrom
			cmd = []
			cmd << "#{aSudo} rm -rf #{aFrom}"
			cmd << "#{aSudo} ln -sf #{aTo} #{aFrom}"
			cmd << "#{aSudo} chown -h #{aUserGroup} #{aFrom}" if aUserGroup
			run cmd.join(' && ')
		end

		def make_public_cache_dir(aStartPath)
			run "#{@context.sudo} mkdir -p #{aStartPath}"
			permissions_for_web(aStartPath)
			permissions_for_web_writable(aStartPath)
		end

	end
end
