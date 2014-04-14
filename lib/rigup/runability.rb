module Rigup
	module Runability

		def shell
			@shell ||= ::Session::Bash.new
		end

		def pwd
			shell.execute("pwd", stdout: nil).first.strip
		end

		def cd(aPath,&block)
			if block_given?
				begin
			 		before_path = pwd
					cd(aPath)
					yield aPath,before_path
				ensure
					cd(before_path)
				end
			else
				aPath = File.expand_path(aPath)
				Dir.chdir(aPath)
				shell.execute("cd \"#{aPath}\"")
			end
			aPath
		end

		def run(aCommand)
			@context.logger.debug aCommand
			response,errout = @shell.execute(aCommand,stdout: STDOUT)  #   ::POpen4::shell(aCommand,aDir || @context.pwd)
			raise Error, "Command Failed" unless @shell.exit_status==0
			return response
		end

		def run_for_all(aCommand,aPath,aFilesOrDirs,aPattern=nil,aInvertPattern=false,aSudo=false)
			#run "#{sudo} find . -wholename '*/.svn' -prune -o -type d -print0 |xargs -0 #{sudo} chmod 750"
			#sudo find . -type f -exec echo {} \;
			cmd = []
			cmd << "sudo" if aSudo
			cmd << "find #{aPath.ensure_suffix('/')}"
			cmd << "-wholename '#{aPattern}'" if aPattern
			cmd << "-prune -o" if aInvertPattern
			cmd << case aFilesOrDirs.to_s[0,1]
				when 'f' then '-type f'
				when 'd' then '-type d'
				else ''
			end
			cmd << "-exec"
			cmd << aCommand
			cmd << "'{}' \\;"
			cmd = cmd.join(' ')
			run cmd
		end

	end
end