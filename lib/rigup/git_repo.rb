require 'git'

module Rigup
	class GitRepo

		include Rigup::Utils::Run

		attr_reader :git,:configured

		GIT_METHODS = [:commit,:add,:reset_hard,:path,:clone,:log,:size,:branches,:status,:remotes,:pull,:fetch,:push,:merge]

		def initialize(aContext=nil)
			@context = (aContext || Rigup::Context.new)
		end

		def method_missing(sym, *args, &block)
			if @git && GIT_METHODS.include?(sym)
				@git.send sym, *args, &block
			else
				super
			end
		end

		def open(aPath)
			@git = ::Git.open(aPath)
		end

		def init(*args)
			@git = ::Git.init(*args)
		end

		def clone(aUrl,aPath)
			@git = ::Git::clone(aUrl,aPath)
		end

		def open?
			!!@git
		end

		def empty?
			!@git.branches[0]
		end

		def status
			result = @git.lib.command_lines('status',['--porcelain'])
			result
		end

		def changes?
			raise RuntimeError.new('Repository must be open') unless open?
			status.length > 0
		end

		def commit_all(*args)
			result = begin
				@git.commit_all(*args)
			rescue ::Git::GitExecuteError => e
				if e.message.index("nothing to commit (working directory clean)")
					nil
				else
					raise e
				end
			end
			result = commitFromString(result)
			result
		end

		# "[master (root-commit) 6bdd9e1] first commit  1 files changed, 1 insertions(+), 0 deletions(-)  create mode 100644 file1.txt"
		def commitFromString(aString)
			return nil if !aString || aString.empty?
			sha = aString.scan(/ ([a-f0-9]+)\]/).flatten.first
			@git.gcommit(sha)
		end

		def path
			@git.dir.path
		end

		def origin
			@git.remotes.find {|r| r.name=='origin'}
		end

		def url
			(o = origin) && o.url
		end

		def checkout(commit=nil,branch=nil)
			specific_commit = !!commit && !commit.index('HEAD')
			if specific_commit
				@git.checkout commit
			else
				branch ||= 'master'
				@git.checkout(branch)
			end
		end

		# http://stackoverflow.com/questions/2866358/git-checkout-only-files-without-repository
		# http://www.clientcide.com/best-practices/exporting-files-from-git-similar-to-svn-export/
		def export(aDest)
			#rsync --exclude=.git /source/directory/ user@remote-server.com:/target-directory
			FileUtils.cp_r(path,aDest)
			FileUtils.rm_rf(File.expand_path('.git',aDest))
		end

		def branch
			@git.current_branch
		end

		def sha
			head.sha
		end

		def head
			@git.log.first
		end

		# ::Git --no-pager diff --name-status 26bb87c3981 191d64820f2b
		# result is array of paths prefixed with status letter then a tab
		# see http://git-scm.com/docs/git-diff under --diff-filter=
		# Added (A), Copied (C), Deleted (D), Modified (M), Renamed (R), have their type (i.e. regular file, symlink, submodule, ...) changed (T)
		def changesBetweenCommits(aFromCommit, aToCommit)
			@git.lib.command_lines('diff',['--name-status',aFromCommit,aToCommit])
		end

		# Added (A), Copied (C), Deleted (D), Modified (M), Renamed (R), have their type (i.e. regular file, symlink, submodule, ...) changed (T)
		def self.convertChangesToUploadsDeletes(changes)
			uploads = []
			deletes = []
			changes.each do |line|
				continue if line==""
				tabi = line.index("\t")
				status = line[0,tabi]
				path = line[tabi+1..-1]
				if status.index('D')
					deletes << path
				else
					uploads << path
				end
			end
			return uploads,deletes
		end

		def get_file_content(aPath,aCommitOrBranch=nil)
			@git.lib.command('show',[[aCommitOrBranch||'master',aPath].join(':')]) rescue nil
		end

	end
end