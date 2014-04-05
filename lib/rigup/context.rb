module Rigup
	class Context

		attr_reader :config, :options, :argv, :env, :stdout, :stdin, :stderr, :key_chain, :credentials, :logger, :pwd, :variant
		attr_writer :pwd

		def sudo
			''
		end

		def initialize(aValues=nil)
			return if !aValues

			#is_client = !!(aValues[:key_chain] || aValues[:global_options] || aValues[:options])
			@config = aValues[:config]
			@pwd = Buzztools::File.real_path(aValues[:pwd] || (@config && @config[:folder]) || Dir.pwd)
			@options = aValues[:options]
			@argv = aValues[:argv]
			@env = aValues[:env]
			@stdout = aValues[:stdout]
			@stdin = aValues[:stdin]
			@stderr = aValues[:stderr]
			@key_chain = aValues[:key_chain]
			@credentials = aValues[:credentials]
			@logger = aValues[:logger]
			@variant = aValues[:variant]
		end

		def git_root
			@git_root ||= find_git_root
		end

		# http://thinkingdigitally.com/archive/capturing-output-from-puts-in-ruby/
		#class SimpleSemParserTest < Test::Unit::TestCase
		#  def test_set_stmt_write
		#    out = capture_stdout do
		#      parser = SimpleSemParser.new
		#      parser.parse('set write, "Hello World!"').execute
		#    end
		#    assert_equal "Hello World!\n", out.string
		#  end
		#end
		def capture_stdout
			stdout_before = @stdout
			out = StringIO.new
      @stdout = out
      yield
      return out.string
    ensure
      @stdout = stdout_before
    end

		def find_git_root
			git_folder = BuzzTools::File.find_upwards(@pwd,'.git')
			return git_folder && git_folder.chomp('/.git')
		end

	end
end
