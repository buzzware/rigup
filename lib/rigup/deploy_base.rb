module Rigup

	# Thor base class extended with rigup utilities
	class DeployBase < Thor

		include Rigup::Base
		include Rigup::Utils::Run
		include Rigup::Utils::Install

	end

end