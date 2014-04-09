require 'rigup'

# This file will be called deploy.thor and lives in the root of the project repositiory, so it is version controlled
# and can be freely modified to suit the project requirements
class Deploy < Rigup::DeployBase  # from gem, sets context and loads rigup.yml into config from site_dir

	# You are free to modify these two tasks to suit your requirements

	desc 'install','install the freshly delivered files'
	def install

		# select_suffixed_file("/config/database.yml")
		# select_suffixed_file("/yore.config.xml")
		# select_suffixed_file("/config/app_config.xml")
		# select_suffixed_file("/system/apache.site")
		#make_public_cache_dir("/public/cache")

		# ensure_link("/log","/log")
		# ensure_link("/pids","/tmp/pids")
		# ensure_link("/uploads","/tmp/uploads")
		# ensure_link("/system","/public/system")

		#run "touch /log/production.log && chown : /log/production.log && chmod 666 /log/production.log"
	end

	desc 'restart','restart the web server'
	def restart
		# run "touch " + File.join("current/tmp/restart.txt",@site_dir) # && chown user:group current/tmp/restart.txt"
		# run "/etc/init.d/apache2 restart --force-reload"
	end

end
