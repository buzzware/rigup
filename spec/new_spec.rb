require 'spec_helper'
#require 'file_utils'

describe 'rigup' do

	before :each do
		@old_dir = Dir.pwd
		Dir.chdir(@dir = Dir.mktmpdir("new_spec"))
	end

	after :each do
		Dir.chdir(@old_dir)
	end

	def new_site_process(aGitUrl)
		@script = Rigup::Cli.new
		@script.invoke(:new, [aGitUrl, 'mysite'])
		Dir.exists?('mysite/releases').should be
		Dir.exists?('mysite/shared').should be
		File.exists?('mysite/rigup.yml').should be

		@config = YAML.load_file('mysite/rigup.yml')
		@config[:git_url].should == aGitUrl
	end

	def mock_get_repo(aUrl,aPath)
		basename = File.basename(aUrl,'.git')
		src = "~/repos/underscore_plus" unless File.exists?(src = "~/repos/#{basename}")
		FileUtils.cp_r(File.expand_path(src),File.expand_path(aPath))
	end

	def stub_out_github
		::Rigup::GitRepo.any_instance.stub(:clone) do |aUrl,aPath|
			mock_get_repo(aUrl,aPath)
		end
	end

RELEASE_INSTALL = <<-EOS
	class Deploy < Thor

	desc 'install','install the freshly delivered files'
	def install
		puts 'install'
	end

	desc 'restart','restart the web server'
	def restart
		puts 'restart'
	end

	end
EOS

	describe "Given new project" do

		it "deploy should update_cache, install and link_live" do
			#Rigup::Cli.any_instance.stub(:restart => true, :install => true)
			new_site_process('https://github.com/buzzware/underscore_plus.git')
			::Rigup::GitRepo.any_instance.stub(:clone) do |aUrl,aPath|
				mock_get_repo(aUrl,aPath)
				RELEASE_INSTALL.to_file(File.join(aPath,'deploy.thor'))
			end

			@script2 = Rigup::Cli.new
			@script2.invoke(:deploy, ['mysite'])

			Dir.exists?('mysite/shared/cached-copy').should be
			Dir.exists?('mysite/shared/cached-copy/.git').should be
			Dir.exists?('mysite/shared/cached-copy/.git').should be

			Dir.exists?('mysite/current').should be

			entries = Dir.entries('mysite/releases')
			entries.length.should == 3
			release_path = entries.last
			release_path.should =~ /#{Time.now.strftime('%Y%m%d%H')}/

			# Release method should write a rigup.yml including branch, commit, stage etc (should not be in repo)
			# Rigup::DeployBase then reads this and makes it accessible to install and restart methods
			# Then we can do things like displaying git commit hash on page as the site knows its own full identity
			release_config = YAML.load_file("mysite/releases/#{release_path}/rigup.yml")
			release_config.should be_a Hash

			cache_repo = ::Rigup::GitRepo.new(Rigup::Context.new)
			cache_repo.open('mysite/shared/cached-copy')

			release_config[:branch].should be
			release_config[:branch].should == cache_repo.branch
			release_config[:commit].should be
			release_config[:commit].should == cache_repo.sha
			release_config[:stage].should == 'live'
		end
	end
end