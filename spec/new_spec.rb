require 'spec_helper'

describe 'rigup' do

	before :each do
		@old_dir = Dir.pwd
		Dir.chdir(@dir = Dir.mktmpdir("new_spec"))
	end

	after :each do
		Dir.chdir(@old_dir)
	end

	it "should create new project" do
		git_url = 'https://github.com/buzzware/underscore_plus'
		script = Rigup::Cli.new
	  script.invoke(:new, [git_url, 'mysite'])
		Dir.exists?('mysite/releases').should be
		Dir.exists?('mysite/shared').should be
		File.exists?('mysite/rigup.yml').should be

		config = YAML.load_file('mysite/rigup.yml')
		config[:git_url].should == git_url
	end



	# 	script.invoke(:update_cache, ['mysite'])
	# 	Dir.exists?('mysite/shared/cached-copy').should be
	# 	Dir.exists?('mysite/shared/cached-copy/.git').should be
	# end




end