class Contactor < Formula
	desc "Manage contacts from the command line via the macOS Contacts framework."
	homepage "https://github.com/kettle/Contactor"
	url "https://github.com/kettle/Contactor/releases/download/1.2.2/Contactor-1.2.2.tar.gz"
	sha256 ""
	version "1.2.2"

	depends_on "curl"

	bottle :unneeded

	def install
		bin.install "Contactor"
	end
end
