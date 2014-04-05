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

	def stub_out_github
		::Rigup::GitRepo.any_instance.stub(:clone) do |aUrl,aPath|
			basename = File.basename(aUrl,'.git')
			src = "~/repos/underscore_plus" unless File.exists?(src = "~/repos/#{basename}")
			FileUtils.cp_r(File.expand_path(src),File.expand_path(aPath))
		end
	end

	describe "Given new project" do

		before :each do
			new_site_process('https://github.com/buzzware/underscore_plus.git')
		end

		it "deploy should update_cache, install and link_live" do
			stub_out_github
			@script2 = Rigup::Cli.new
			@script2.invoke(:deploy, ['mysite'])

			Dir.exists?('mysite/shared/cached-copy').should be
			Dir.exists?('mysite/shared/cached-copy/.git').should be
			Dir.exists?('mysite/shared/cached-copy/.git').should be

			Dir.entries('mysite/releases').last.should =~ /#{Time.now.strftime('%Y%m%d%H')}/

			Dir.exists?('mysite/current').should be

		end
	end
end