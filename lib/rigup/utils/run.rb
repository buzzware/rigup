module Rigup
	module Utils
		module Run

			def bash
				@bash ||= ::Session::Bash.new
			end

			def pwd
				bash.execute("pwd", stdout: nil).first.strip
			end

			def cd(aPath,&block)
				if block_given?
					begin
				    before_path = pwd
						cd(aPath)
						yield aPath,before_path
					rescue Exception => e
						logger.info e.message
					ensure
						cd(before_path)
					end
				else
					aPath = File.expand_path(aPath)
					Dir.chdir(aPath)
					bash.execute("cd \"#{aPath}\"")
				end
				aPath
			end

			def run(aCommand,aOptions=nil)
				aOptions ||= {}
				logger.debug aCommand
				response,errout = bash.execute(aCommand,stdout: STDOUT)  #   ::POpen4::shell(aCommand,aDir || @context.pwd)
				logger.debug errout if errout.to_nil
				logger.debug response if response.to_nil
				raise "Command Failed" unless bash.exit_status==0 or aOptions[:raise]==false
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
end