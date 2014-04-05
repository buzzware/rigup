module Rigup

	class Contextable
		module Rigup
			attr_accessor :context

			def initialise(aContext)
				@context = aContext
			end

			def run(aCommand)
				context.logger.debug aCommand
				response = POpen4::shell(aCommand,context.working_path)
				raise Error, "Command Failed" unless (response && response[:exitcode]==0)
				return response[:stdout]
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

end
